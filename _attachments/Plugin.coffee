# Use global to enable calling this from question sets
global.GeoHierarchy = new (require './GeoHierarchy')()
global.FacilityHierarchy = new (require './FacilityHierarchy')()
global.Case = require './Case'
global.HouseholdLocationSelectorView = require './HouseholdLocationSelectorView'
global.SummaryView = require './SummaryView'

_.delay ->
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

  Coconut.menuView.renderHeader = ->

    new_case_url = "#zanzibar/show/results/Case Notification"
    update_case_url = "##{Coconut.databaseName}/find/case"
    followup_url = "##{Coconut.databaseName}/followups"
    $(".mdl-layout__header-row").html "
      #{
        Coconut.questions.map (question) ->
          questionId = question.get "_id"
          url = "#zanzibar/show/results/#{questionId}"
          "
            <a style='padding-right:20px' class='drawer_question_set_link' href='#{url}'>#{questionId} <span id='incomplete_#{question.safeLabel()}'></span></a>
            <!--
            <a class='drawer_question_set_link' href='#{url}'><i class='mdl-color-text--accent material-icons'>add</i></a>
            -->
          "
        .join ""
      }
      <a style='padding-right:20px' class='drawer_question_set_link' href='#zanzibar/summary'>Summary</a>
      <a style='position:absolute; top:0px; right:0px;' class='mdl-navigation__link' href='##{Coconut.databaseName}/sync'><i class='mdl-color-text--accent material-icons'>sync</i>Sync</a>
    "

    incompleteResults = {}
    Coconut.questions.each (question) ->
      incompleteResults[question.get("_id")] = 0


    Coconut.database.query "results/results",
      include_docs: false
    .then (result) ->
      _(result.rows).each (row) ->
        incompleteResults[row.key[0]] += 1 if row.key[1] is false

      _(incompleteResults).each (amount, question) ->
        $("#incomplete_#{question.replace(/ /g,'')}").html amount
    .catch (error) ->
      console.error error

  Coconut.menuView.renderHeader()
, 1000


module.exports = Plugin
