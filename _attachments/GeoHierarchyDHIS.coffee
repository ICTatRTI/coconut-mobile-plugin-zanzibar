_ = require 'underscore'

class GeoHierarchy

  constructor: (options) ->

    Coconut.database.get "dhis2"
    .catch (error) ->
      console.error "Error loading Geo Hierarchy:"
      console.error error
      options.error(error)
    .then (result) =>

      @data = result

      @levels = _(result.organisationUnitLevels).chain()
        .sortBy (organisationUnitLevel) ->
          organisationUnitLevel.level
        .map (organisationUnitLevel) ->
          organisationUnitLevel.name.toUpperCase()

      levelNumberToName = {}
      _(result.organisationUnitLevels).each (level) =>
        levelNumberToName[level.level] = level.name.toUpperCase()

      # Tidy up the object
      _(result.organisationUnits).each (organisationUnit) ->
        organisationUnit.level = levelNumberToName[organisationUnit.level]
        organisationUnit.name = organisationUnit.name.toUpperCase()
        _([
          "created"
          "lastUpdated"
          "externalAccess"
          "user"
          "shortName"
          "id"
          "openingDate"
        ]).each (property) -> delete organisationUnit[property]

      # Load up the district translation mapping
      Coconut.database.get "district_language_mapping"
      .catch (error) ->
        console.error "Error loading district_language_mapping:"
        console.error error
        options.error(error)
      .then (result) =>
        @englishToSwahiliDistrictMapping = result.english_to_swahili
        options?.success?()

  swahiliDistrictName: (district) =>
    @englishToSwahiliDistrictMapping[district] or district
      
  englishDistrictName: (district) =>
    _(@englishToSwahiliDistrictMapping).invert()[district] or district

  findInNodes: (nodes, requiredProperties) =>
    _(nodes).where requiredProperties

  find: (name,level) =>
    @findInNodes(@data.organisationUnits, {name: name.toUpperCase() if name, level:level.toUpperCase() if level})

  findFirst: (name,level) ->
    result = @find(name,level)
    if result? then result[0] else {}

  findAllForLevel: (level) =>
    @findInNodes(@data.organisationUnits, {level: level})

  findAllDescendantsAtLevel: (name, sourceLevel, targetLevel) =>

    findDescendants = (node) =>
      console.log node
      if node.level is targetLevel
        node
      else
        # TODO levels are names not numbers
        _(_(@findInNodes(@data.organisationUnits, {level: @levels[node.level+1})).filter (node) ->
          console.log node
          node.parent.name.toUpperCase() is node.name.toUpperCase()
        ).map (node) ->
          findDescendants(node)

    findDescendants(@findInNodes(@data.organisationUnits, {level:sourceLevel, name: name}))

  findShehia: (targetShehia) =>
    @find(targetShehia,"SHEHIA")

  findOneShehia: (targetShehia) =>
    shehia = @findShehia(targetShehia)
    switch shehia.length
      when 0 then return null
      when 1 then return shehia[0]
      else
        return undefined

  validShehia: (shehia) =>
    @findShehia(shehia)?.length > 0

  findAllShehiaNamesFor: (name, level) =>
    _.pluck @findAllDescendantsAtLevel(name, level, "SHEHIA"), "name"

  findAllDistrictsFor: (name, level) =>
    _.pluck @findAllDescendantsAtLevel(name, level, "DISTRICT"), "name"

  allRegions: =>
    _.pluck @findAllForLevel("REGION"), "name"

  allDistricts: =>
    _.pluck @findAllForLevel("DISTRICT"), "name"

  allShehias: =>
    _.pluck @findAllForLevel("SHEHIA"), "name"

  allUniqueShehiaNames: =>
    _(_.pluck @findAllForLevel("SHEHIA"), "name").uniq()

  all: (geographicHierarchy) =>
    _.pluck @findAllForLevel(geographicHierarchy.toUpperCase()), "name"

  # TODO This isn't going to work
  update: (region,district,shehias) =>
    @hierarchy[region][district] = shehias
    geoHierarchy = new GeoHierarchy()
    geoHierarchy.fetch
      error: (error) -> console.error JSON.stringify error
      success: (result) =>
        geoHierarchy.save "hierarchy", @hierarchy,
          error: (error) -> console.error JSON.stringify error
          success: () ->
            Coconut.debug "GeoHierarchy saved"
            @load

  @getZoneForDistrict: (district) ->
    districtHierarchy = @find(district,"DISTRICT")
    if districtHierarchy.length is 1
      region = @find(district,"DISTRICT")[0].REGION
      return @getZoneForRegion region
    return null

  @getZoneForRegion: (region) ->
    if region.match /PEMBA/
      return "PEMBA"
    else
      return "UNGUJA"

  @districtsForZone = (zone) =>
    _.chain(@allRegions())
      .map (region) =>
        if @getZoneForRegion(region) is zone
          @findAllDistrictsFor(region, "REGION")
      .flatten()
      .compact()
      .value()

module.exports = GeoHierarchy
