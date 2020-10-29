#Router Plugins

Router::default = =>
  Backbone.history.loadUrl()
  Coconut.router.navigate "##{Coconut.databaseName}/summary",trigger: true

Coconut.router._bindRoutes()

Coconut.router.route ":database/summary", ->
  Coconut.summaryView ?= new SummaryView()
  oneMonthAgo = moment().subtract(1, "months").format("YYYY-MM-DD")
  Case.getCasesSummaryData(oneMonthAgo, moment().format("YYYY-MM-DD"))
  .catch (error) =>
    console.error JSON.stringify error
  .then (cases) =>
    console.log cases
    Coconut.summaryView.render cases

Coconut.router.route ":database/transfer/:caseID", (caseID) ->
  if Coconut.currentUser
    Coconut.transferView ?= new TransferView()
    Coconut.transferView.caseID = caseID
    Coconut.transferView.render()
