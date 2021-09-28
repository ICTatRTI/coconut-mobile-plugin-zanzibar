# Use global to enable calling this from question sets
DHISHierarchy = require './DHISHierarchy'
GeoHierarchyClass = require './GeoHierarchy'
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
    require './QuestionPlugins'
    require './QuestionViewPlugins'
    require './ResultsViewPlugins'
    require './Form2jsPlugins'
    Coconut.cachingDatabase = new PouchDB("coconut-zanzibar-caching")
    Coconut.notificationsDB = new PouchDB(Coconut.config.cloud_url_with_credentials_no_db() + "/notifications-#{Coconut.databaseName}")

    await Case.setup()

    global.GeoHierarchy = new GeoHierarchyClass()
    await GeoHierarchy.load()
    await QuestionCollection?.load() # Reload questions to use QuestionPlugins

    resolve()

global.StartPlugins = [] unless StartPlugins?
StartPlugins.push onStartup


module.exports = Plugin
