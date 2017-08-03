HeaderView::questionTabs = (options) ->
  menuIcons = { 'Case Notification':'wifi', 'Facility':'hospital', 'Household':'home-map-marker', 'Household Members':'account'}
  if Coconut.questions
    navlinks = (Coconut.questions.map (question,index) ->
      results_url = "##{Coconut.databaseName}/show/results/#{escape(question.id)}"
      spanID = question.id.replace(/\s/g,"_")
      "<a class='mdl-navigation__link top_links' href='#{results_url}'><span id='#{spanID}' class='mdl-badge' data-badge=''><i class='mdl-layout--small-screen-only mdi mdi-#{menuIcons[question.id]}'></i> <span class='mdl-layout--large-screen-only'>#{question.id}</span></span></a>"
    .join(" "))
    $('nav.mdl-navigation').html(navlinks)

HeaderView::update = ->
  Coconut.questions.each (question,index) =>
    Coconut.database.query "results/results",
      startkey: [question.id, false]
      endkey: [question.id, false, {}]
      include_docs: false
      (error,result) =>
        console.log error if error
        $("span##{question.id.replace(/\s/g,'_')}").attr('data-badge', result.rows.length)
