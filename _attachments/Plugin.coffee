# Use global to enable calling this from question sets
DHISHierarchy = require './DHISHierarchy'
GeoHierarchyClass = require './GeoHierarchy'
#global.FacilityHierarchy = new (require './FacilityHierarchy')()
global.Case = require './Case'
global.HouseholdLocationSelectorView = require './HouseholdLocationSelectorView'
global.SummaryView = require './SummaryView'
global.TransferView = require './TransferView'
Sync = require './Sync'


onStartup = ->

  try
    require './RouterPlugins'
    require './HeaderViewPlugins'

    dhisHierarchy = new DHISHierarchy()
    dhisHierarchy.loadExtendExport
      dhisDocumentName: "dhis2" # This is the document that was exported from DHIS2
      error: (error) -> console.error error
      success: (result) ->
        global.GeoHierarchy = new GeoHierarchyClass(result)
        global.FacilityHierarchy = GeoHierarchy # These have been combined

        # Replacing sync
  #  require './ExtendSync'
        Coconut.syncView.sync = new Sync()
        Coconut.cloudDatabase = new PouchDB(Coconut.config.cloud_url_with_credentials())

  catch error
    console.error "PLUGIN ERROR:"
    console.error error

      # originalResultsViewRender = ResultsView::render
      # ResultsView::render = ->
      #   originalResultsViewRender.apply(this,arguments)
      #   # Select the not complete panel by default
      #   # TODO figure out how to do this without using a delay
      #   _.delay( ->
      #     $("[href='#not-complete-panel']")[0].click()
      #   , 500)

global.StartPlugins = [] unless StartPlugins?
StartPlugins.push onStartup

module.exports = Plugin
