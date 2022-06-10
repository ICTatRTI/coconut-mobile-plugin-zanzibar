global.Case = require './Case'

global.awesompleteByName = {}

QuestionView::initialize = ->
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
      element.html(labelText.replace(/Zanzibar.*/, 'Zanzibar between the ' + start.format('Do of MMM, YYYY') + ' (' + start.fromNow()  + ') and ' + end.format('Do of MMM, YYYY') + ' (' + end.fromNow() + ')*' ))
  , 2000

global.convertDayNumbersToDatesRelativeToDiagnosisDateAndAddSelector = (labelText) ->
  convertDayNumbersToDatesRelativeToDiagnosisDate(labelText)
  element = $("label:contains('#{labelText}')")
  new HouseholdLocationSelectorView(element)

global.markCompleteAndExit = =>
  if confirm("This will mark the question set as complete, are you sure?")
    _.delay => # Small delay to allow other activities, including validation which may switch complete field
      # MARK COMPLETE AND CLOSE
      $("[name=complete]").prop("checked", true)
      await Coconut.questionView.save()
      Coconut.router.navigate("#{Coconut.databaseName}/show/results/#{escape(Coconut.questionView.result.questionName())}",true)
    ,1000

QuestionView::render = ->

  @primary1 = "rgb(63,81,181)"
  @primary2 = "rgb(48,63,159)"

  @accent1 = "rgb(230,33,90)"
  @accent2 = "rgb(194,24,91)"

  @$el.html "
  <style>#{unless @isRepeatableQuestionSet then @css() else ""}</style>

  <div class='question_container'>
    <div style='position:fixed; right:5px; color:white; padding:20px; z-index:5' id='messageText'>
    </div>

    <div style='position:fixed; right:5px; color:white; background-color: #333; padding:20px; display:none; z-index:10' id='messageText'>
      Saving...
    </div>


    <h4 class='content_title'>#{@model.id}</h4>
    <div id='askConfirm'></div>
    <div id='question-view'>
      <form id='questions'>
        #{@toHTMLForm(@model)}
      </form>
    </div>
  </div>
  "

  for name, questionSet of @model.repeatableQuestionSets
    questionSet.view = new RepeatableQuestionSetView
        questionSet: questionSet
        targetRepeatableField: @$("[name=#{slugify(name)}]")

  componentHandler.upgradeDom()
  # Hack since upgradeDom doesn't add is-dirty class to previously filled in fields
  _.delay =>
    @$('input[type=text]').filter( -> this.value isnt "").closest('div').addClass('is-dirty')
    @$('input[type=number]').filter( -> this.value isnt "").closest('div').addClass('is-dirty')
    @updateLabelClass()
  , 500

  #Load data into form
  if @result

    @addRepeatableQuestionSets()
    @loadResultsInForm()

  @updateCache()

  # for first run
  @updateSkipLogic()

  # skipperList is a list of questions that use skip logic in their action on change events
  skipperList = []

  if @model.get("action_on_questions_loaded")? and @model.get("action_on_questions_loaded") isnt ""
    CoffeeScript.eval @model.get "action_on_questions_loaded"

  $(@model.get("questions")).each (index, question) =>

    # remember which questions have skip logic in their actionOnChange code
    skipperList.push(question.safeLabel()) if question.actionOnChange().match(/skip/i)

    if question.get("action_on_questions_loaded")? and question.get("action_on_questions_loaded") isnt ""
      global.currentLabel = question.get "label"
      CoffeeScript.eval question.get "action_on_questions_loaded"

  # Trigger a change event for each of the questions that contain skip logic in their actionOnChange code
  @triggerChangeIn skipperList

  autocompleteElements = []
  _.each @$("input[type='autocomplete from list']"), (element) =>
    awesompleteByName[element.name] = new Awesomplete element,
      list: $(element).attr("data-autocomplete-options").replace(/\n|\t/,"").split(/, */)
      minChars: 1
      maxItems: 15
      #filter: Awesomplete.FILTER_STARTSWITH

    autocompleteElements.push element

  _.each @$("input[type='autocomplete from code']"), (element) ->
    awesompleteByName[element.name] = new Awesomplete element,
      list: eval($(element).attr("data-autocomplete-options"))
      minChars: 1
      filter: Awesomplete.FILTER_STARTSWITH

  _.each @$("input[type='autocomplete from previous entries']"), (element) =>
    Coconut.database.query "resultsByQuestionAndField",
      startkey: [@model.get("id"),$(element).attr("name")]
      endkey: [@model.get("id"),$(element).attr("name"), {}]
    .catch (error) ->
      console.log "Error while doing autcomplete from previous entries for"
      console.log element
      console.log error
    .then (result) ->
      awesompleteByName[element.name] = new Awesomplete element,
        list: _(result.rows).chain().pluck("value").unique().value()
        minChars: 1
        filter: Awesomplete.FILTER_STARTSWITH

  _.each autocompleteElements, (autocompeteElement) =>
    autocompeteElement.blur =>
      @autoscroll autocompeteElement
  @$('input, textarea').attr("readonly", "true") if @readonly

  # Without this re-using the view results in staying at the old scroll position
  @$("main").scrollTop(0)
