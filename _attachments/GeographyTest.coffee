PouchDB = require "/var/www/coconut-mobile/_attachments/node_modules/pouchdb/"
DHISHierarchy = require './DHISHierarchy'
GeoHierarchy = require "./GeoHierarchy"
GeoHierarchyOld = require "./GeoHierarchyOld"
FacilityHierarchy = require "./FacilityHierarchy"
global._ = require "/var/www/coconut-mobile/_attachments/node_modules/underscore/"

assert = require 'assert'
colors = require 'colors'

###
process.on 'Error', (err) ->
  console.log err

process.on 'uncaughtException', (err) ->
  console.log err
###
global.Coconut =
  database: new PouchDB("http://localhost:5984/zanzibar")

dhisHierarchy = new DHISHierarchy()
dhisHierarchy.loadExtendExport
  error: (error) -> console.error error
  success: (result) ->
    geoHierarchy = new GeoHierarchy(result)
#        console.log geoHierarchy.units[30]
#        console.log geoHierarchy.units[30].parent()
#    console.log geoHierarchy.units[30].ancestors()

    facilityHierarchy = new FacilityHierarchy
      error: (error) => console.log error
      success: =>
        console.log "LOADED LEGACY FacilityHierarchy"

       geoHierarchyOld = new GeoHierarchyOld
        success: ->

          testFunction = (functionName, argument, debug = true, applyAfter) ->
            console.log functionName.green
            argument = [argument] unless Array.isArray(argument)
           
            newResult = geoHierarchy[functionName].apply(@, argument)
            oldResult = geoHierarchyOld[functionName].apply(@, argument)

            # Can pass in property to call or function to call or an array of either
            applyAfterHandler = (result, applyAfter) ->
              if _.isArray(applyAfter)
                if applyAfter.length is 0
                  return result
                else
                  return applyAfterHandler(applyAfterHandler(result,applyAfter.shift()), applyAfter)
              else if _.isFunction(result[applyAfter])
                result[applyAfter]()
              else
                result[applyAfter]

            if applyAfter
              newResult = applyAfterHandler(newResult,JSON.parse(JSON.stringify(applyAfter)))
              oldResult = applyAfterHandler(oldResult,JSON.parse(JSON.stringify(applyAfter)))

            if debug
              console.log "New".yellow
              console.log newResult
              console.log "Old".yellow
              console.log oldResult

            assert.equal newResult,oldResult




          testFunctionFacility = (functionName, argument, debug = true, applyAfter) ->
            console.log functionName.green
            argument = [argument] unless Array.isArray(argument)
           
            newResult = geoHierarchy[functionName].apply(@, argument)
            oldResult = facilityHierarchy[functionName].apply(@, argument)

            # Can pass in property to call or function to call or an array of either
            applyAfterHandler = (result, applyAfter) ->
              if _.isArray(applyAfter)
                if applyAfter.length is 0
                  return result
                else
                  return applyAfterHandler(applyAfterHandler(result,applyAfter.shift()), applyAfter)
              else if _.isFunction(result[applyAfter])
                result[applyAfter]()
              else
                result[applyAfter]

            if applyAfter
              newResult = applyAfterHandler(newResult,JSON.parse(JSON.stringify(applyAfter)))
              oldResult = applyAfterHandler(oldResult,JSON.parse(JSON.stringify(applyAfter)))

            if debug
              console.log "New".yellow
              console.log newResult
              console.log "Old".yellow
              console.log oldResult

            assert.equal newResult,oldResult








          try
            console.log geoHierarchy.find("CENTRAL","DISTRICT")
            console.log geoHierarchy.find("KATI","DISTRICT")
            console.log geoHierarchy.swahiliDistrictName("CENTRAL")
            #swahiliDistrictName: (district) =>
            testFunction("swahiliDistrictName","CENTRAL")
            testFunction("swahiliDistrictName","KATI")
            #englishDistrictName: (district) =>
            testFunction("englishDistrictName","KATI")
            testFunction("englishDistrictName","CENTRAL")
            #findInNodes: (nodes, requiredProperties) =>
            # TODO
            #find: (name,level) =>
            console.log "find".green
            newFind = geoHierarchy.find("WETE","DISTRICT")
            oldFind = geoHierarchyOld.find("WETE","DISTRICT")
            assert.equal newFind.name, oldFind.name
            assert.equal newFind.level, oldFind.level
            #findFirst: (name,level) ->
            console.log "findFirst".green
            newFind = geoHierarchy.findFirst("WETE","DISTRICT")
            oldFind = geoHierarchyOld.findFirst("WETE","DISTRICT")
            assert.equal newFind.name, oldFind.name
            #findAllForLevel: (level) =>
            console.log "findAllForLevel".green
            newAllFacilities = _(geoHierarchy.findAllForLevel("FACILITY")).pluck("name").sort()
            oldAllFacilities = facilityHierarchy.allFacilities().sort()
            #assert.equal newAllFacilities.length, oldAllFacilities.length
            console.log (_.difference(oldAllFacilities, newAllFacilities)).toString().red

            #findAllDescendantsAtLevel: (name, sourceLevel, targetLevel) =>
            newFindAllDescendantsAtLevel = _(geoHierarchy.findAllDescendantsAtLevel("WETE","DISTRICT","SHEHIA")).pluck("name").sort()
            oldFindAllDescendantsAtLevel = _(geoHierarchyOld.findAllDescendantsAtLevel("WETE","DISTRICT","SHEHIA")).pluck("name").sort()
            
            console.log (_.difference(newFindAllDescendantsAtLevel, oldFindAllDescendantsAtLevel)).toString().red

            #findShehia: (targetShehia) =>
            testFunction("findOneShehia", "BOPWE", false, "name")
            #validShehia: (shehia) =>
            testFunction("validShehia", "BOPWE")
            testFunction("validShehia", "KATI")
            #testFunction("findAllShehiaNamesFor", ["CENTRAL", "DISTRICT"])
            testFunction("findAllDistrictsFor", ["KUSINI PEMBA", "REGION"], true, ["sort","toString"])
            testFunction("allRegions", null, false, ["sort","toString"])
            testFunction("allDistricts", null, false, ["sort","toString"])
            testFunction("allShehias", null, false, ["sort","toString"])
            testFunction("allUniqueShehiaNames", null, false, ["sort","toString"])
            testFunction("all", "DISTRICT", false, ["sort","toString"])
            #testFunction("all", "ZONE", true)
            testFunction("getZoneForDistrict", "KATI", true)
            testFunction("getZoneForRegion", "KASKAZINI PEMBA", false)
            testFunction("districtsForZone", "PEMBA", false, ["sort", "toString"])
#            testFunctionFacility("allFacilities", null, true, ["sort", "toString"])
            console.log (_.difference(facilityHierarchy.allFacilities(), geoHierarchy.allFacilities())).toString().red
            testFunctionFacility("getDistrict", "BAMBI")
            ###
            # FacilityHierarchy depends on GeoHierarchy so not easy to test
            testFunctionFacility("getZone", "BAMBI")
            ###
            console.log (_.difference(facilityHierarchy.facilities("KATI"), geoHierarchy.facilities("KATI"))).toString().red
            #testFunctionFacility("facilities", "KATI", false, ["sort","toString"])
            #testFunctionFacility("facilitiesForDistrict", "KATI", false, ["sort","toString"])
            #console.log (_.difference(facilityHierarchy.facilitiesForZone("PEMBA"), geoHierarchy.facilitiesForZone("PEMBA"))).toString().red
            #testFunctionFacility("facilitiesForZone", "PEMBA", false, ["sort","toString"])
            testFunctionFacility("numbers", ["KATI","MWERA"], false, ["sort","toString"])
            testFunctionFacility("facilityType", "BAMBI")
            #testFunctionFacility("allPrivateFacilities", null, true, ["sort", "toString"])
            console.log (_.difference(facilityHierarchy.allPrivateFacilities(), geoHierarchy.allPrivateFacilities())).toString().red


            #update: (district,targetFacility,numbers, options) =>
          catch error
            console.log error.stack
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
