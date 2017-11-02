originalResultsViewRender = ResultsView::render
ResultsView::render = ->
  originalResultsViewRender.apply(this,arguments)
  # Select the not complete panel by default
  # TODO figure out how to do this without using a delay
  _.delay( ->
    $("[href='#not-complete-panel']")[0].click() if $("[href='#not-complete-panel']")[0]
  , 500)
