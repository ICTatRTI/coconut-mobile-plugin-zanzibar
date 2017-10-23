global.Case = require './Case'

console.log "AZZZZZ"

QuestionView::initialize = ->
  Coconut.resultCollection ?= new ResultCollection()
  @autoscrollTimer = 0
  @loadCase()

QuestionView::loadCase  = ->
  malariaCaseId = ResultOfQuestion('Malaria Case ID')
  if malariaCaseId
    window.currentCase = new Case
      caseID: malariaCaseId
    window.currentCase.fetch()
  else
    _.delay @loadCase, 2000

# Not used anymore
global.updateOutsideZanzibarLabel = (element,startDays,endDays) ->
  _.delay ->
    start = moment(currentCase.indexCaseDiagnosisDate()).subtract(startDays,'days')
    end = moment(currentCase.indexCaseDiagnosisDate()).subtract(endDays,'days')
    $(element).html($(element).html().replace(/Zanzibar.*/, 'Zanzibar between the ' + start.format('Do of MMM, YYYY') + ' (' + start.fromNow()  + ') and ' + end.format('Do of MMM, YYYY') + ' (' + end.fromNow() + ')' ))
  , 2000

global.convertDayNumbersToDatesRelativeToDiagnosisDate = (labelText) ->
  element = $("label:contains('#{labelText}')")
  _.delay ->
    if currentCase
      # For example "All locations and entry points from overnight travel outside Zanzibar 43-365 days before positive test result"
      matches = labelText.match(/(\d+)-(\d+)/)
      beginningRange = matches[1]
      endRange = matches[2]

      start = moment(currentCase.indexCaseDiagnosisDate()).subtract(endRange,'days')
      end = moment(currentCase.indexCaseDiagnosisDate()).subtract(beginningRange,'days')
      element.html(labelText.replace(/Zanzibar.*/, 'Zanzibar between the ' + start.format('Do of MMM, YYYY') + ' (' + start.fromNow()  + ') and ' + end.format('Do of MMM, YYYY') + ' (' + end.fromNow() + ')' ))
  , 2000

global.convertDayNumbersToDatesRelativeToDiagnosisDateAndAddSelector = (labelText) ->
  convertDayNumbersToDatesRelativeToDiagnosisDate(labelText)
  element = $("label:contains('#{labelText}')")
  new HouseholdLocationSelectorView(element)
