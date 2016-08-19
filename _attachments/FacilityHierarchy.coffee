# Coconut.database needs to be set

class FacilityHierarchy

  constructor: (options) ->

    Coconut.database.get "Facility Hierarchy"
    .then (result) =>
      @hierarchy = result.hierarchy
      # This is crappy programming - why is this static, but I can't refactor now
      @databaseObject = result
      options?.success?()
    .catch (error) ->
      console.error error
      options?.error?()

  #Note that the facilities after the line break are hospitals

  allDistricts: =>
    _.keys(@hierarchy).sort()

  allFacilities: =>
    _.chain(@hierarchy).values().flatten().pluck("facility").value()

  getDistrict: (facility) =>
    facility = facility.trim() if facility
    result = null
    _.each @hierarchy, (facilityData,district) ->
      if _.chain(facilityData).pluck("facility").contains(facility).value()
        result = district
    return result if result

    # Still no match? - check aliases
    _.each @hierarchy, (facilityData,district) ->
      if _.chain(facilityData).pluck("aliases").flatten().compact().contains(facility).value()
        result = district
    return result

  getZone: (facility) =>
    district = @getDistrict facility
    districtHierarchy = GeoHierarchy.find(district,"DISTRICT")
    if districtHierarchy.length is 1
      region = GeoHierarchy.find(district,"DISTRICT")[0].REGION
      if region.match /PEMBA/
        return "PEMBA"
      else
        return "UNGUJA"

    return null

  facilities: (district) =>
    _.pluck @hierarchy[district], "facility"

  facilitiesForDistrict: (district) =>
    @facilities(district)

  facilitiesForZone: (zone) =>
    districtsInZone = GeoHierarchy.districtsForZone(zone)
    _.chain(districtsInZone)
      .map (district) =>
        @facilities(district)
      .flatten()
      .value()

    @facilities(district)

  numbers: (district,facility) =>
    _(@hierarchy[district]).find (result) ->
      result.facility is facility
    .mobile_numbers

  update: (district,targetFacility,numbers, options) =>
    console.log numbers

    facilityIndex = -1
    _(@hierarchy[district]).find (facility) ->
      facilityIndex++
      facility['facility'] is targetFacility

    if facilityIndex is -1
      @hierarchy[district].push {
        facility: targetFacility
        mobile_numbers: numbers
      }

    else
      @hierarchy[district][facilityIndex] =
        facility: targetFacility
        mobile_numbers: numbers

    @databaseObject.hierarchy = @hierarchy
    Coconut.database.put @databaseObject
    .catch(error) -> console.error error
    .then(response) =>
      @databaseObject._rev = response.rev
      options?.success()

  facilityType: (facilityName) =>
    result = null
    _.each @hierarchy, (facilities,district) ->
      if result is null
        facility = _.find facilities, (facility) ->  facility.facility is facilityName
        result = facility.type.toUpperCase() if facility
    return result

  allPrivateFacilities: =>
    _.chain(@hierarchy).values().flatten().filter( (facility) -> facility.type is "private" ).pluck("facility").value()

module.exports = FacilityHierarchy
