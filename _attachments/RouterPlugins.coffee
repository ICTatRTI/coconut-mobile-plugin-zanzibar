#Router Plugins

Router::default = =>
  Backbone.history.loadUrl()
  Coconut.router.navigate "##{Coconut.databaseName}/summary",trigger: true

Coconut.router._bindRoutes()

Coconut.router.route ":database/summary", ->
  console.log "summary called"
  Coconut.summaryView ?= new SummaryView()
  Coconut.database.query "casesWithSummaryData",
    descending: true
    include_docs: false
    limit: 100
  .catch (error) =>
    console.error JSON.stringify error
  .then (result) =>
    Coconut.summaryView.render result

Coconut.router.route ":database/transfer/:caseID", (caseID) ->
  if Coconut.currentUser
    Coconut.transferView ?= new TransferView({caseID: caseID})
    Coconut.transferView.render()
