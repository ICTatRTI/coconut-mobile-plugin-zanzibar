global.Case = require './Case'

QuestionView::initialize = ->
  Coconut.resultCollection ?= new ResultCollection()
  @autoscrollTimer = 0

global.convertDayNumbersToDatesRelativeToDiagnosisDate = (labelText) ->
  element = $("label:contains('#{labelText}')")
  _.delay ->
    if malariaCase
      # For example "All locations and entry points from overnight travel outside Zanzibar 43-365 days before positive test result"
      matches = labelText.match(/(\d+)-(\d+)/)
      beginningRange = matches[1]
      endRange = matches[2]

      start = moment(malariaCase.indexCaseDiagnosisDate()).subtract(endRange,'days')
      end = moment(malariaCase.indexCaseDiagnosisDate()).subtract(beginningRange,'days')
      element.html(labelText.replace(/Zanzibar.*/, 'Zanzibar between the ' + start.format('Do of MMM, YYYY') + ' (' + start.fromNow()  + ') and ' + end.format('Do of MMM, YYYY') + ' (' + end.fromNow() + ')' ))
  , 2000

global.convertDayNumbersToDatesRelativeToDiagnosisDateAndAddSelector = (labelText) ->
  convertDayNumbersToDatesRelativeToDiagnosisDate(labelText)
  element = $("label:contains('#{labelText}')")
  new HouseholdLocationSelectorView(element)
