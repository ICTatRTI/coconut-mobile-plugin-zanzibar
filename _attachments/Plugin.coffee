# Use global to enable calling this from question sets
DHISHierarchy = require './DHISHierarchy'
GeoHierarchyClass = require './GeoHierarchy'
#global.FacilityHierarchy = new (require './FacilityHierarchy')()
global.Case = require './Case'
global.HouseholdLocationSelectorView = require './HouseholdLocationSelectorView'
global.SummaryView = require './SummaryView'
global.TransferView = require './TransferView'
require './SyncPlugins'

onStartup = ->
  new Promise (resolve) =>
    require './RouterPlugins'
    require './HeaderViewPlugins'
    require './MenuViewPlugins'
    require './QuestionViewPlugins'
    require './ResultsViewPlugins'
    require './Form2jsPlugins'

    await Case.setup()

    console.log "Loading DHIS2 Hierarchy"

    dhisHierarchy = new DHISHierarchy()
    dhisHierarchy.loadExtendExport
      dhisDocumentName: "dhis2" # This is the document that was exported from DHIS2
      error: (error) -> console.error error
      success: (result) ->
        global.GeoHierarchy = new GeoHierarchyClass(result)
        global.FacilityHierarchy = GeoHierarchy # These have been combined
        console.log "DHIS2 Hierarchy Loaded"
        resolve()

global.StartPlugins = [] unless StartPlugins?
StartPlugins.push onStartup


module.exports = Plugin
