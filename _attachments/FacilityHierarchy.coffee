# Coconut.database needs to be set

class FacilityHierarchy

  FacilityHierarchy.fetch = (options) ->
    Coconut.database.get "Facility Hierarchy"
    .catch (error) ->
      console.error error
      options.error(error)
    .then (result) ->
      options.success(result)

  #Note that the facilities after the line break are hospitals

  FacilityHierarchy.load = (options) ->
    FacilityHierarchy.fetch
      success: (result) ->
        FacilityHierarchy.hierarchy = result.hierarchy
        # This is crappy programming - why is this static, but I can't refactor now
        FacilityHierarchy.databaseObject = result
        options.success()
      error: (error) ->
        console.error "Error loading Facility Hierarchy: #{JSON.stringify(error)}"
        options.error(error)

  FacilityHierarchy.allDistricts = ->
    _.keys(FacilityHierarchy.hierarchy).sort()

  FacilityHierarchy.allFacilities = ->
    _.chain(FacilityHierarchy.hierarchy).values().flatten().pluck("facility").value()

  FacilityHierarchy.getDistrict = (facility) ->
    facility = facility.trim() if facility
    result = null
    _.each FacilityHierarchy.hierarchy, (facilityData,district) ->
      if _.chain(facilityData).pluck("facility").contains(facility).value()
        result = district
    return result if result

    # Still no match? - check aliases
    _.each FacilityHierarchy.hierarchy, (facilityData,district) ->
      if _.chain(facilityData).pluck("aliases").flatten().compact().contains(facility).value()
        result = district
    return result

  FacilityHierarchy.getZone = (facility) ->
    district = FacilityHierarchy.getDistrict facility
    districtHierarchy = GeoHierarchy.find(district,"DISTRICT")
    if districtHierarchy.length is 1
      region = GeoHierarchy.find(district,"DISTRICT")[0].REGION
      if region.match /PEMBA/
        return "PEMBA"
      else
        return "UNGUJA"

    return null

  FacilityHierarchy.facilities = (district) ->
    _.pluck FacilityHierarchy.hierarchy[district], "facility"

  FacilityHierarchy.facilitiesForDistrict = (district) ->
    FacilityHierarchy.facilities(district)

  FacilityHierarchy.facilitiesForZone = (zone) ->
    districtsInZone = GeoHierarchy.districtsForZone(zone)
    _.chain(districtsInZone)
      .map (district) ->
        FacilityHierarchy.facilities(district)
      .flatten()
      .value()

    FacilityHierarchy.facilities(district)

  FacilityHierarchy.numbers = (district,facility) ->
    foundFacility =  _(FacilityHierarchy.hierarchy[district]).find (result) ->
      result.facility is facility
    foundFacility["mobile_numbers"]

  FacilityHierarchy.update = (district,targetFacility,numbers, options) ->
    console.log numbers

    facilityIndex = -1
    _(FacilityHierarchy.hierarchy[district]).find (facility) ->
      facilityIndex++
      facility['facility'] is targetFacility

    if facilityIndex is -1
      FacilityHierarchy.hierarchy[district].push {
        facility: targetFacility
        mobile_numbers: numbers
      }

    else
      FacilityHierarchy.hierarchy[district][facilityIndex] =
        facility: targetFacility
        mobile_numbers: numbers

    FacilityHierarchy.databaseObject.hierarchy = FacilityHierarchy.hierarchy
    Coconut.database.put FacilityHierarchy.databaseObject
    .catch(error) -> console.error error
    .then(response) ->
      FacilityHierarchy.databaseObject._rev = response.rev
      options?.success()

  FacilityHierarchy.facilityType = (facilityName) ->
    result = null
    _.each FacilityHierarchy.hierarchy, (facilities,district) ->
      if result is null
        facility = _.find facilities, (facility) ->  facility.facility is facilityName
        result = facility.type.toUpperCase() if facility
    return result

  FacilityHierarchy.allPrivateFacilities = ->
    _.chain(FacilityHierarchy.hierarchy).values().flatten().filter( (facility) -> facility.type is "private" ).pluck("facility").value()



FacilityHierarchy.load
  success: ->
    console.log "FacilityHierarchy loaded"
