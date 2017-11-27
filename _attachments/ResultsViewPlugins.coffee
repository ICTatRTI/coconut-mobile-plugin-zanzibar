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
      , 500
    else
      _.delay((-> clickWhenAvailable(elementId)), 500)

  clickWhenAvailable("not-complete-panel")
