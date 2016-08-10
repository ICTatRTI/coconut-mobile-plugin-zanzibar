_ = require 'underscore'

class DHISHierarchy

  constructor: (options) ->

    Coconut.database.get "dhis2"
    .catch (error) ->
      console.error "Error loading Geo Hierarchy:"
      console.error error
      options?.error(error)
    .then (result) =>
      @rawData = result
      options?.success()

  export: =>
    # Tidy up the object

    dataForExport = @rawData

    propertiesToDelete = [
      "created"
      "lastUpdated"
      "externalAccess"
      "user"
      "shortName"
      "openingDate"
      "uuid"
      "publicAccess"
    ]

    dataForExport.organisationUnits = _(dataForExport.organisationUnits).map (organisationUnit) ->
      organisationUnit.name = organisationUnit.name.toUpperCase()
      _(propertiesToDelete).each (property) -> delete organisationUnit[property]
      if organisationUnit.parent
        organisationUnit.parentId = organisationUnit.parent.id
        organisationUnit.source = "dhis2"
        delete organisationUnit.parent
      return organisationUnit

    delete dataForExport.organisationUnitGroupSets

    dataForExport.organisationUnitGroups =  _(dataForExport.organisationUnitGroups).map (organisationUnitGroup) ->
      _(propertiesToDelete).each (property) -> delete organisationUnitGroup[property]
      organisationUnitGroup.source = "dhis2"
      organisationUnitGroup.organisationUnits = _(organisationUnitGroup.organisationUnits).map (organisationUnit) ->
        organisationUnit.id
        organisationUnit.source = "dhis2"
      return organisationUnitGroup


    dataForExport.organisationUnitLevels =  _(dataForExport.organisationUnitLevels).map (organisationUnitLevel) ->
      _(propertiesToDelete).each (property) -> delete organisationUnitLevel[property]
      organisationUnitLevel.source = "dhis2"
      return organisationUnitLevel

    return dataForExport

  extend: =>
    dataToExtendWith = {
      organisationUnitLevels: [
        { name: "Shehia", level: 6, id: "pqommz", source: "coconutSurveillance" }
        { name: "Village", level: 7, id: "qpzmak", source: "coconutSurveillance" }
      ]

      organisationUnitGroups: [
      ]

      organisationUnits: [
        { name: "BOPWE", level: 6, id: "asaaaa", parentName: "WETE", parentType: "District", source: "coconutSurveillance" }
        { name: "CHAMBANI", level: 6, id: "bsaaaa", parentName: "MKOANI", parentType: "District", source: "coconutSurveillance" }
        { name: "AMANI", level: 6, id: "rraaaa", parentName: "MJINI", parentType: "District", source: "coconutSurveillance" }
      ]
    }

    returnVal = @export()

    # Look up parents for organisationUnits based on the existing data
    #
    dataToExtendWith.organisationUnits = _(dataToExtendWith.organisationUnits).map (organisationUnit) ->

      if not organisationUnit.parentId and organisationUnit.parentName and organisationUnit.parentType
        # Get the level number for the parentType, eg District is level 4
        organisationUnitParentLevel = _(returnVal.organisationUnitLevels).find (level) ->
          organisationUnit.parentType is level.name
        organisationUnitParentLevel = organisationUnitParentLevel.level # just want the number

        parentOrganizationUnit = _(returnVal.organisationUnits).filter (existingOrganisationUnit) ->
          existingOrganisationUnit.level is organisationUnitParentLevel and existingOrganisationUnit.name is organisationUnit.parentName
        if parentOrganizationUnit.length > 1
          console.log "Multiple parent matches for #{JSON.stringify organisationUnit}:\n #{JSON.stringify parentOrganizationUnit}"
          throw "Multiple parent matches for #{organisationUnit}"
        else if parentOrganizationUnit.length is 1
          organisationUnit.parentId = parentOrganizationUnit[0].id
          delete organisationUnit.parentName
          delete organisationUnit.parentType
        else
          console.log "No parent found for #{JSON.stringify organisationUnit}"
      return organisationUnit

    arrayPropertiesToExtend = [
      "organisationUnitLevels"
      "organisationUnitGroups"
      "organisationUnits"
    ]

    _(arrayPropertiesToExtend).each (property) ->
      returnVal[property] = returnVal[property].concat(dataToExtendWith[property])

    return returnVal

module.exports = DHISHierarchy
