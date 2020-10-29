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
    require './QuestionViewPlugins'
    require './ResultsViewPlugins'
    require './Form2jsPlugins'
    Coconut.cachingDatabase = new PouchDB("coconut-zanzibar-caching")

    await Case.setup()

    global.GeoHierarchy = new GeoHierarchyClass()
    await GeoHierarchy.load()

    resolve()

global.StartPlugins = [] unless StartPlugins?
StartPlugins.push onStartup


module.exports = Plugin
