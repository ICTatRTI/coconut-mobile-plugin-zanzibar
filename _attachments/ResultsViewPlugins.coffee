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
    cases = await Case.getCases()
    transferredCases = {}
    for malariaCase in cases
      lastTransferEntry = _(malariaCase["Facility"]?.transferred).last()
      console.log lastTransferEntry
      if lastTransferEntry?.from is Coconut.currentUser.id
        transferredCases[malariaCase.caseID] = true

    console.log transferredCases

    indexOfCaseId = $("th:contains(Malaria Case ID)").index()
    for row in $(".results tbody tr")
      console.log "ZZZ"
      id = $(row).find("td")[indexOfCaseId]?.innerText
      console.log id
      console.log transferredCases[id]
      if transferredCases[id]
        for td in $(row).find("td")
          #console.log td.innerText
          $(td).html("<span style='text-decoration:line-through'>#{td.innerText}</span>")
      
    
  clickWhenAvailable("not-complete-panel")
