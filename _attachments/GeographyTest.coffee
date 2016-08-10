process.on 'Error', (err) ->
  console.log err

PouchDB = require "/var/www/coconut-mobile/_attachments/node_modules/pouchdb/"
GeoHierarchy = require "./GeoHierarchy"
DHISHierarchy = require './DHISHierarchy'
FacilityHierarchy = require "./FacilityHierarchy"
global._ = require "/var/www/coconut-mobile/_attachments/node_modules/underscore/"

assert = require 'assert'
colors = require 'colors'

global.Coconut =
  database: new PouchDB("http://localhost:5984/zanzibar")

dhisHierarchy = new DHISHierarchy
  success: ->
    process.on 'Error', (err) ->
      console.log err
    console.log dhisHierarchy.extend()

return

geoHierarchy = new GeoHierarchy
  error: (error) => console.log error
  success: =>
    console.log "LOADED LEGACY GeoHierarchy"


    newFormat = {}

    convertNode = (node) ->
      console.log node
      if node.children
       console.log  children
       return  {
          name: node.name
          children: _(node.children).map (childNode) ->
            convertNode(childNode)
        }
      else
        return null

    #convertNode(geoHierarchy.root)
    console.log convertNode(geoHierarchy.root)
    #
    exit


    facilityHierarchy = new FacilityHierarchy
      error: (error) => console.log error
      success: =>
        console.log "LOADED LEGACY FacilityHierarchy"

        testFunction = (functionName, argument, debug = false) ->
          console.log functionName.green
          argument = [argument] unless Array.isArray(argument)
          if debug
            console.log geoHierarchy[functionName].apply(@, argument)
            console.log geoHierarchyDHIS[functionName].apply(@, argument)

          assert.equal geoHierarchy[functionName].apply(@, argument), geoHierarchyDHIS[functionName].apply(@, argument)
          #assert geoHierarchy[functionName](argument) is geoHierarchyDHIS[functionName](argument)

        try
          #swahiliDistrictName: (district) =>
          testFunction("swahiliDistrictName","WETE")
          testFunction("swahiliDistrictName","CENTRAL")
          #englishDistrictName: (district) =>
          testFunction("englishDistrictName","WETE")
          testFunction("englishDistrictName","CENTRAL")
          #findInNodes: (nodes, requiredProperties) =>
          # TODO
          #find: (name,level) =>
          console.log "find".green
          dhisFind = geoHierarchyDHIS.find("WETE","DISTRICT")
          oldFind = geoHierarchy.find("WETE","DISTRICT")
          assert.equal dhisFind.name, oldFind.name
          assert.equal dhisFind.level, oldFind.level
          #findFirst: (name,level) ->
          console.log "findFirst".green
          dhisFind = geoHierarchyDHIS.findFirst("WETE","DISTRICT")
          oldFind = geoHierarchy.findFirst("WETE","DISTRICT")
          assert.equal dhisFind.name, oldFind.name
          #findAllForLevel: (level) =>
          console.log "findAllForLevel".green
          dhisAllFacilities = _(geoHierarchyDHIS.findAllForLevel("FACILITY")).pluck("name").sort()
          oldAllFacilities = facilityHierarchy.allFacilities().sort()
          #assert.equal dhisAllFacilities.length, oldAllFacilities.length
          console.log (_.difference(oldAllFacilities, dhisAllFacilities)).toString().red

          #findAllDescendantsAtLevel: (name, sourceLevel, targetLevel) =>
          console.log geoHierarchyDHIS.findAllDescendantsAtLevel("WETE","DISTRICT","SHEHIA")
          #findShehia: (targetShehia) =>
          #findOneShehia: (targetShehia) =>
          #validShehia: (shehia) =>
          #findAllShehiaNamesFor: (name, level) =>
          #findAllDistrictsFor: (name, level) =>
          #allRegions: =>
          #allDistricts: =>
          #allShehias: =>
          #allUniqueShehiaNames: =>
          #all: (geographicHierarchy) =>
          #update: (region,district,shehias) =>
          #@getZoneForDistrict: (district) ->
          #@getZoneForRegion: (region) ->
          #@districtsForZone = (zone) =>
          #
          #
          #



          #allDistricts: =>
          #allFacilities: =>
          #getDistrict: (facility) =>
          #getZone: (facility) =>
          #facilities: (district) =>
          #facilitiesForDistrict: (district) =>
          #facilitiesForZone: (zone) =>
          #numbers: (district,facility) =>
          #update: (district,targetFacility,numbers, options) =>
          #facilityType: (facilityName) =>
          #allPrivateFacilities: =>
        catch error
          console.log error
###
# REGION 
#   DISTRICT 
#     SHEHIA
"KASKAZINI PEMBA": {
   "WETE": [
     "BOPWE",
     "CHWALE",
     "FUNDO",
     ....
###
