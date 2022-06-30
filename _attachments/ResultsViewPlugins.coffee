originalResultsViewRender = ResultsView::render
ResultsView::render = ->

  originalResultsViewRender.apply(this,arguments)

  onReady = =>
    if @tabulator?

      # Don't allow deletion of Case Notification or Facility records
      if @question.id is "Case Notification" or @question.id is "Facility"
        @$(".mdi-delete").hide()

       updateCaseList()

    else
      _.delay =>
        onReady()
      , 200

  updateCaseList = =>
    casesToHide = {}
    for malariaCase in await Case.getCasesSummaryData()
      lastTransferEntry = _(malariaCase["Facility"]?.transferred).last()
      if lastTransferEntry?.from is Coconut.currentUser.id
        casesToHide[malariaCase.caseID] = true
      if malariaCase.status is "Lost To Followup"
        casesToHide[malariaCase.caseID] = true

    for row in Coconut.resultsView.tabulator.getRows()
      if Object.keys(casesToHide).includes row.getData().MalariaCaseID
        @tabulator.deleteRow(row)
    
  onReady()
