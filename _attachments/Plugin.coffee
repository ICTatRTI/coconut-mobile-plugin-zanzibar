# Use global to enable calling this from question sets
global.GeoHierarchy = new (require './GeoHierarchy')()
global.FacilityHierarchy = new (require './FacilityHierarchy')()
global.Case = require './Case'
global.HouseholdLocationSelectorView = require './HouseholdLocationSelectorView'

_.delay ->
  ###
  Coconut.router.route ":database/find/case", ->
    Coconut.findCaseView = new FindCaseView() unless Coconut.findCaseView
    Coconut.findCaseView.render()
  ###

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
