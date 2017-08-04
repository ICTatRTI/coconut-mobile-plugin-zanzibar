# MenuView Plugins

MenuView::questionLinks = (option) ->
  Coconut.questions.fetch
    success: =>
      menuIcons = { 'Case Notification':'wifi', 'Facility':'hospital', 'Household':'home-map-marker', 'Household Members':'account'}
      $("#drawer_question_sets").html (Coconut.questions.map (question,index) ->
        new_url = "##{Coconut.databaseName}/new/result/#{escape(question.id)}"
        results_url = "##{Coconut.databaseName}/show/results/#{escape(question.id)}"
        spanID = question.id.replace(/\s/g,"_")
        "
          <div>
            <a class='mdl-navigation__link' href='#{results_url}'><span id='#{spanID}' class='#{spanID} mdl-badge' data-badge=''><i class='mdl-color-text--accent mdi mdi-#{menuIcons[question.id]}'></i>
            <span>#{question.id}</span></span></a>
          </div>
        "
      .join(" "))

      componentHandler.upgradeDom()
      @hideMenuOptions()
      Coconut.headerView.update()

MenuView::generalMenu = ->
  $("#drawer_general_menu").html (
    _([
      "##{Coconut.databaseName}/sync,sync,Sync data"
      "##{Coconut.databaseName}/reset/database,alert,Reset database"
      "##{Coconut.databaseName}/manage,wrench,Manage"
      "##{Coconut.databaseName}/logout,logout,Logout"
    ]).map (linkData) ->
      [url,icon,linktext] = linkData.split(",")
      "<a class='mdl-navigation__link' href='#{url}' id='#{linktext.toLowerCase()}'><i class='mdl-color-text--blue-grey-400 mdi mdi-#{icon}'></i>#{linktext}</a>"
    .join("")
  )

MenuView::update = ->
  Coconut.questions.each (question,index) =>

  Coconut.database.query "results",
    startkey: [question.id, true]
    endkey: [question.id, true, {}]
    include_docs: false
    (error,result) =>
      console.log error if error

      $("#complete_results").html result.rows.length
