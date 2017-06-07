# Use global to enable calling this from question sets
DHISHierarchy = require './DHISHierarchy'
GeoHierarchyClass = require './GeoHierarchy'
#global.FacilityHierarchy = new (require './FacilityHierarchy')()
global.Case = require './Case'
global.HouseholdLocationSelectorView = require './HouseholdLocationSelectorView'
global.SummaryView = require './SummaryView'
Sync = require './Sync'


onStartup = ->

  try
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

        # Replacing defaults
        # Router::default = =>
        #   console.log('Inside plugin default')
        #   Coconut.router.navigate("##{Coconut.databaseName}/summary",true)

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
              <style>
                th.header { text-align: left;}
                table.dataTable tbody td { padding: 8px 20px;}
              </style>
              <h3 class='content_title'>Select a user to transfer #{caseID} to:</h3>
              <select id='users'>
                <option></option>
              </select>
              <br/>
              <button onClick='window.history.back()'>Cancel</button>
              <br />
              <h4>Case Results to be transferred:</h4>
            "
            caseResults = []

            Coconut.database.query "cases",
              key: caseID
              include_docs: true
            ,
              (error, result) =>
                console.error error if error

                caseResults = _.pluck(result.rows, "doc")
                console.log(caseResults)
                Coconut.database.query "usersByDistrict", {},
                  (error,result) ->
                    $("#content select").append(_(result.rows).map (user) ->
                      return "" unless user.key?
                      "<option id='#{user.id}'>#{user.key}   #{user.value.join("   ")}</option>"
                    .join "")
                $("#content").append "
                  <div>
                    <table id='summary' class='tablesorter hover'>
                      <thead><tr>
                        <th class='header'>Case ID</th>
                        <th class='header'>Question</th>
                        <th class='header'>Complete?</th>
                      </tr></thead>
                      <tbody>
                        #{
                          _(caseResults).map (caseResult) ->
                            completed = if caseResult.complete == true then 'Yes' else 'No'
                            console.log(completed)
                            result = "
                              <tr>
                                <td>#{caseResult.MalariaCaseID}</td>
                                <td>#{caseResult.question}</td>
                                <td>#{completed}</td>
                              </tr>
                            "
                          .join ""
                        }
                      </tbody>
                    </table>
                  </div>
                "
                $("table#summary").DataTable
                  aaSorting: [[0,"desc"]]
                  scrollX: true
                  searching: false
                  paging: false
                  info: false
                  drawCallback: () ->
                    $(".dataTables_scrollHeadInner").css("width":"100%")
                    $(".dataTable.no-footer").css("width":"100%")

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
