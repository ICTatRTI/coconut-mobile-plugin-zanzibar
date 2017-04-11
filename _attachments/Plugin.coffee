# Use global to enable calling this from question sets
DHISHierarchy = require './DHISHierarchy'
GeoHierarchyClass = require './GeoHierarchy'
#global.FacilityHierarchy = new (require './FacilityHierarchy')()
global.Case = require './Case'
global.HouseholdLocationSelectorView = require './HouseholdLocationSelectorView'
global.SummaryView = require './SummaryView'
Sync = require './Sync'


onStartup = ->


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

      Coconut.router.route ":database/summary", ->
        Coconut.summaryView ?= new SummaryView()
        Coconut.database.query "casesWithSummaryData",
          descending: true
          include_docs: false
          limit: 100
        ,
          (error,result) =>
            if error
              console.error JSON.stringify error
            else
              Coconut.summaryView.render result

      Coconut.router.route ":database/transfer/:caseID", (caseID) ->
        if Coconut.currentUser
          $("#content").html "
            <h2>
            Select a user to transfer #{caseID} to:
            </h2>
            <select id='users'>
              <option></option>
            </select>
            <br/>
            <button onClick='window.history.back()'>Cancel</button>
            <h3>Case Results to be transferred</h3>
            <div id='caseinfo'></div>
          "
          caseResults = []

          Coconut.database.query "cases",
            key: caseID
            include_docs: true
          ,
            (error, result) =>
              console.error error if error

              caseResults = _.pluck(result.rows, "doc")
              Coconut.database.query "usersByDistrict", {},
                (error,result) ->
                  $("#content select").append(_(result.rows).map (user) ->
                    return "" unless user.key?
                    "<option id='#{user.id}'>#{user.key}   #{user.value.join("   ")}</option>"
                  .join "")
              $("#caseinfo").html (_(caseResults).map (caseResult) ->
                "
                  <pre>
                    #{JSON.stringify(caseResult, null, 2)}
                  </pre>
                "
              .join("<br/>"))

          $("select").change ->
            user = $('select').find(":selected").text()
            if confirm "Are you sure you want to transfer Case:#{caseID} to #{user}?"
              _(caseResults).each (caseResult) ->
                Coconut.debug "Marking #{caseResult._id} as transferred"
                caseResult.transferred = [] unless caseResult.transferred?
                caseResult.transferred.push {
                  from: Coconut.currentUser.get("_id")
                  to: $('select').find(":selected").attr "id"
                  time: moment().format("YYYY-MM-DD HH:mm")
                  notifiedViaSms: []
                  received: false
                }
              Coconut.cloudDatabase.bulkDocs {docs: caseResults}
              .catch (error) ->
                console.error "Could not save #{JSON.stringify caseResults}:"
                console.error error
              .then () ->
                Coconut.router.navigate("",true)


      originalResultsViewRender = ResultsView::render
      ResultsView::render = ->
        originalResultsViewRender.apply(this,arguments)
        # Select the not complete panel by default
        # TODO figure out how to do this without using a delay
        _.delay( ->
          $("[href='#not-complete-panel']")[0].click()
        , 500)



global.StartPlugins = [] unless StartPlugins?
StartPlugins.push onStartup

module.exports = Plugin
