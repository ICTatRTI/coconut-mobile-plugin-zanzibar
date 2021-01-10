originalResultsViewRender = ResultsView::render
ResultsView::render = ->
  originalResultsViewRender.apply(this,arguments)
  # Select the not complete panel by default
  # TODO figure out how to do this without using a delay
  #
  clickWhenAvailable = (elementId) ->
    if $("[href='##{elementId}']").length > 0
      _.delay ->
        $("[href='##{elementId}']")[0].click()
        removeTransferredCases()
      , 500
    else
      _.delay((-> clickWhenAvailable(elementId)), 500)

  removeTransferredCases = =>
    cases = await Case.getCasesSummaryData()
    transferredCases = {}
    for malariaCase in cases
      lastTransferEntry = _(malariaCase["Facility"]?.transferred).last()
      if lastTransferEntry?.from is Coconut.currentUser.id
        transferredCases[malariaCase.caseID] = true

    indexOfCaseId = $("th:contains(Malaria Case ID)").index()
    for row in $(".results tbody tr")
      id = $(row).find("td")[indexOfCaseId]?.innerText
      if transferredCases[id]
        for td in $(row).find("td")
          $(td).html("<span style='text-decoration:line-through'>#{td.innerText}</span>")
      
    
  clickWhenAvailable("not-complete-panel")

  originalLoadResults = ResultsView::loadResults
  ResultsView::loadResults = ->
    originalLoadResults.apply(this,arguments)
    # Disable delete for Case Notification so that cases don't accidentally get lost
    # hack it with the delay
    _.delay =>
      if @question.id is "Case Notification" or @question.id is "Facility"
        @$(".mdi-delete").hide()
    , 1000
