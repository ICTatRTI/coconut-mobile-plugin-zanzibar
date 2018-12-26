# TODO Clean Data:  - old data was not camel cases properly
# HeadofHouseholdName -> HeadOfHouseholdName
#
#      ContactMobilePatientRelative
#      TotalNumberOfResidentsInTheHousehold
#        Household.Numberofotherhouseholdswithin50stepsofindexcasehousehold
#       ReasonForVisitingHousehold

class Case
  constructor: (options) ->
    @caseID = options?.caseID
    @loadFromResultDocs(options.results) if options?.results


  loadFromResultDocs: (resultDocs) ->
    @caseResults = resultDocs
    @questions = []
    this["Household Members"] = []
    this["Neighbor Households"] = []

    userRequiresDeidentification = (Coconut.currentUser?.hasRole("reports") or Coconut.currentUser is null) and not Coconut.currentUser?.hasRole("admin")

    _.each resultDocs, (resultDoc) =>
      resultDoc = resultDoc.toJSON() if resultDoc.toJSON?

      if userRequiresDeidentification
        _.each resultDoc, (value,key) ->
          resultDoc[key] = b64_sha1(value) if value? and _.contains(Coconut.identifyingAttributes, key)

      if resultDoc.question
        @caseID ?= resultDoc["MalariaCaseID"]
        throw "Inconsistent Case ID" if @caseID isnt resultDoc["MalariaCaseID"]
        @questions.push resultDoc.question
        if resultDoc.question is "Household Members"
          this["Household Members"].push resultDoc
        else if resultDoc.question is "Household" and resultDoc.Reasonforvisitinghousehold is "Index Case Neighbors"
          this["Neighbor Households"].push resultDoc
        else
          if resultDoc.question is "Facility"
            dateOfPositiveResults = resultDoc.DateofPositiveResults
            if dateOfPositiveResults?
              dayMonthYearMatch = dateOfPositiveResults.match(/^(\d\d).(\d\d).(20\d\d)/)
              if dayMonthYearMatch
                [day,month,year] = dayMonthYearMatch[1..]
                if day > 31 or month > 12
                  console.error "Invalid DateOfPositiveResults: #{this}"
                else
                  resultDoc.DateofPositiveResults = "#{year}-#{month}-#{day}"

          if this[resultDoc.question]?
            # Duplicate
            if this[resultDoc.question].complete is "true" and (resultDoc.complete isnt "true")
              console.log "Using the result marked as complete"
              return #  Use the version already loaded which is marked as complete
            else if this[resultDoc.question].complete and resultDoc.complete
              console.warn "Duplicate complete entries for case: #{@caseID}"
          this[resultDoc.question] = resultDoc
      else
        @caseID ?= resultDoc["caseid"]
        if @caseID isnt resultDoc["caseid"]
          console.log resultDoc
          console.log resultDocs
          throw "Inconsistent Case ID. Working on #{@caseID} but current doc has #{resultDoc["caseid"]}: #{JSON.stringify resultDoc}"
        @questions.push "USSD Notification"
        this["USSD Notification"] = resultDoc


  fetch: (options) =>
    unless @caseID
      console.error "No caseID to fetch data for"
      return
    Coconut.database.query "cases/cases",
      key: @caseID
      include_docs: true
    .catch (error) -> options?.error()
    .then (result) =>
      @loadFromResultDocs(_.pluck(result.rows, "doc"))
      options?.success()

  toJSON: =>
    returnVal = {}
    _.each @questions, (question) =>
      returnVal[question] = this[question]
    return returnVal

  deIdentify: (result) ->

  flatten: (questions = @questions) ->
    returnVal = {}
    _.each questions, (question) =>
      type = question
      _.each this[question], (value, field) ->
        if _.isObject value
          _.each value, (arrayValue, arrayField) ->
            returnVal["#{question}-#{field}: #{arrayField}"] = arrayValue
        else
          returnVal["#{question}:#{field}"] = value
    returnVal

  LastModifiedAt: ->
    _.chain(@toJSON())
    .map (question) ->
      question.lastModifiedAt
    .max (lastModifiedAt) ->
      lastModifiedAt?.replace(/[- :]/g,"")
    .value()

  Questions: ->
    _.keys(@toJSON()).join(", ")

  MalariaCaseID: ->
    @caseID

  user: ->
    userId = @.Household?.user || @.Facility?.user || @["Case Notification"]?.user

  facility: ->
    @["USSD Notification"]?.hf or @["Case Notification"]?.FacilityName

  validShehia: ->
    # Try and find a shehia is in our database
    if @.Household?.Shehia and GeoHierarchy.findOneShehia(@.Household.Shehia)
      return @.Household?.Shehia
    else if @.Facility?.Shehia and GeoHierarchy.findOneShehia(@.Facility.Shehia)
      return @.Facility?.Shehia
    else if @["Case Notification"]?.Shehia and GeoHierarchy.findOneShehia(@["Case Notification"]?.Shehia)
      return @["Case Notification"]?.Shehia
    else if @["USSD Notification"]?.shehia and GeoHierarchy.findOneShehia(@["USSD Notification"]?.shehia)
      return @["USSD Notification"]?.shehia

    return null

  shehia: ->
    returnVal = @validShehia()
    return returnVal if returnVal?

    console.warn "No valid shehia found for case: #{@MalariaCaseID()} result will be either null or unknown"

    # If no valid shehia is found, then return whatever was entered (or null)
    @.Household?.Shehia || @.Facility?.Shehia || @["USSD Notification"]?.shehia

  # Want best guess for the district - try and get a valid shehia, if not use district for reporting facility
  district: ->
    shehia = @validShehia()
    if shehia?
      return GeoHierarchy.findOneShehia(shehia).DISTRICT
    else
      console.warn "#{@MalariaCaseID()}: No valid shehia found, using district of reporting health facility (which may not be where the patient lives)"
      district = GeoHierarchy.swahiliDistrictName @["USSD Notification"]?.facility_district
      if _(GeoHierarchy.allDistricts()).include district
        return district
      else
        console.warn "#{@MalariaCaseID()}: The reported district (#{district}) used for the reporting facility is not a valid district. Looking up the district for the health facility name."
        district = GeoHierarchy.swahiliDistrictName(FacilityHierarchy.getDistrict @["USSD Notification"]?.hf)
        if _(GeoHierarchy.allDistricts()).include district
          return district
        else
          console.warn "#{@MalariaCaseID()}: The health facility name (#{@["USSD Notification"]?.hf}) is not valid. Giving up and returning UNKNOWN."
          return "UNKNOWN"

  highRiskShehia: (date) =>
    date = moment().startOf('year').format("YYYY-MM") unless date
    _(Coconut.shehias_high_risk[date]).contains @shehia()

  locationBy: (geographicLevel) =>
    return @district() if geographicLevel.match(/district/i)
    return @validShehia() if geographicLevel.match(/shehia/i)

  possibleQuestions: ->
    ["Case Notification", "Facility","Household","Household Members"]

  questionStatus: =>
    result = {}
    _.each @possibleQuestions(), (question) =>
      if question is "Household Members"
        result["Household Members"] = true
        _.each @["Household Members"]?, (member) ->
          result["Household Members"] = false if member.complete is "false"
      else
        result[question] = (@[question]?.complete is "true")
    return result

  complete: =>
    @questionStatus()["Household Members"] is true

  hasCompleteFacility: =>
    @.Facility?.complete is "true"

  notCompleteFacilityAfter24Hours: =>
    @moreThan24HoursSinceFacilityNotifed() and not @hasCompleteFacility()


  notFollowedUpAfter48Hours: =>
    @moreThan48HoursSinceFacilityNotifed() and not @followedUp()

  followedUpWithin48Hours: =>
    not @notFollowedUpAfter48Hours()

  # Includes any kind of travel including only within Zanzibar
  indexCaseHasTravelHistory: =>
    @.Facility?.TravelledOvernightinpastmonth?.match(/Yes/) or false

  indexCaseHasNoTravelHistory: =>
    not @indexCaseHasTravelHistory()

  followedUp: =>
    @.Household?.complete is "true" or @.Facility?.Hassomeonefromthesamehouseholdrecentlytestedpositiveatahealthfacility is "Yes"

  location: (type) ->
    # Not sure how this works, since we are using the facility name with a database of shehias
    #WardHierarchy[type](@toJSON()["Case Notification"]?["FacilityName"])
    GeoHierarchy.findOneShehia(@toJSON()["Case Notification"]?["FacilityName"])?[type.toUpperCase()]

  withinLocation: (location) ->
    return @location(location.type) is location.name

  completeIndexCaseHouseholdMembers: =>
    _(@["Household Members"]).filter (householdMember) =>
      householdMember.HeadOfHouseholdName is @["Household"].HeadOfHouseholdName and householdMember.complete is "true"

  hasCompleteIndexCaseHouseholdMembers: =>
    @completeIndexCaseHouseholdMembers().length > 0

  positiveCasesAtIndexHousehold: ->
    _(@completeIndexCaseHouseholdMembers()).filter (householdMember) ->
      householdMember.MalariaTestResult is "PF" or householdMember.MalariaTestResult is "Mixed"

  hasAdditionalPositiveCasesAtIndexHousehold: =>
    @positiveCasesAtIndexHousehold().length > 0

  completeNeighborHouseholds: =>
    _(@["Neighbor Households"]).filter (household) =>
      household.complete is "true"

  completeNeighborHouseholdMembers: =>
    _(@["Household Members"]).filter (householdMember) =>
      householdMember.HeadOfHouseholdName isnt @["Household"].HeadOfHouseholdName and householdMember.complete is "true"

  hasCompleteNeighborHouseholdMembers: =>
    @completeIndexCaseHouseholdMembers().length > 0

  positiveCasesAtNeighborHouseholds: ->
    _(@completeNeighborHouseholdMembers()).filter (householdMember) ->
      householdMember.MalariaTestResult is "PF" or householdMember.MalariaTestResult is "Mixed"

  positiveCasesAtIndexHouseholdAndNeighborHouseholds: ->
    _(@["Household Members"]).filter (householdMember) =>
      householdMember.MalariaTestResult is "PF" or householdMember.MalariaTestResult is "Mixed"

  numberPositiveCasesAtIndexHouseholdAndNeighborHouseholds: ->
    @positiveCasesAtIndexHouseholdAndNeighborHouseholds().length

  numberHouseholdOrNeighborMembers: ->
    @["Household Members"].length

  numberHouseholdOrNeighborMembersTested: ->
    _(@["Household Members"]).filter (householdMember) =>
      householdMember.MalariaTestResult is "NPF"
    .length

  positiveCasesIncludingIndex: ->
    if @["Facility"]
      @positiveCasesAtIndexHouseholdAndNeighborHouseholds().concat(_.extend @["Facility"], @["Household"])
    else if @["USSD Notification"]
      @positiveCasesAtIndexHouseholdAndNeighborHouseholds().concat(_.extend @["USSD Notification"], @["Household"], {MalariaCaseID: @MalariaCaseID()})

  indexCasePatientName: ->
    if @["Facility"]?.complete is "true"
      return "#{@["Facility"].FirstName} #{@["Facility"].LastName}"
    if @["USSD Notification"]?
      return @["USSD Notification"]?.name
    if @["Case Notification"]?
      return @["Case Notification"]?.Name

  indexCaseDiagnosisDate: ->
    if @["Facility"]?.DateofPositiveResults?
      date = @["Facility"].DateofPositiveResults
      if date.match(/^20\d\d/)
        return moment(@["Facility"].DateofPositiveResults).format("YYYY-MM-DD")
      else
        return moment(@["Facility"].DateofPositiveResults, "DD-MM-YYYY").format("YYYY-MM-DD")
    else if @["USSD Notification"]?
      return moment(@["USSD Notification"].date).format("YYYY-MM-DD")

  householdMembersDiagnosisDate: ->
    returnVal = []
    _.each @["Household Members"]?, (member) ->
      returnVal.push member.lastModifiedAt if member.MalariaTestResult is "PF" or member.MalariaTestResult is "Mixed"

  resultsAsArray: =>
    _.chain @possibleQuestions()
    .map (question) =>
      @[question]
    .flatten()
    .compact()
    .value()

  fetchResults: (options) =>
    results = _.map @resultsAsArray(), (result) =>
      returnVal = new Result()
      returnVal.id = result._id
      returnVal

    count = 0
    _.each results, (result) ->
      result.fetch
        success: ->
          count += 1
          options.success(results) if count >= results.length
    return results


  updateCaseID: (newCaseID) ->
    @fetchResults
      success: (results) ->
        _.each results, (result) ->
          throw "No MalariaCaseID" unless result.attributes.MalariaCaseID?
          result.save
            MalariaCaseID: newCaseID

  issuesRequiringCleaning: () ->
    # Case has multiple USSD notifications
    resultCount = {}
    questionTypes = "USSD Notification, Case Notification, Facility, Household, Household Members".split(/, /)
    _.each questionTypes, (questionType) ->
      resultCount[questionType] = 0

    _.each @caseResults, (result) ->
      resultCount["USSD Notification"]++ if result.caseid?
      resultCount[result.question]++ if result.question?

    issues = []
    _.each questionTypes[0..3], (questionType) ->
      issues.push "#{resultCount[questionType]} #{questionType}s" if resultCount[questionType] > 1
    issues.push "Not followed up" unless @followedUp()
    issues.push "Orphaned result" if @caseResults.length is 1
    issues.push "Missing case notification" unless @["Case Notification"]? or @["Case Notification"]?.length is 0

    return issues


  allResultsByQuestion: ->
    returnVal = {}
    _.each "USSD Notification, Case Notification, Facility, Household".split(/, /), (question) ->
      returnVal[question] = []

    _.each  @caseResults, (result) ->
      if result["question"]?
        returnVal[result["question"]].push result
      else if result.hf?
        returnVal["USSD Notification"].push result

    return returnVal

  redundantResults: ->
    redundantResults = []
    _.each @allResultsByQuestion, (results, question) ->
      console.log _.sort(results, "createdAt")

  daysBetweenPositiveResultAndNotification: =>

    dateOfPositiveResults = if @["Facility"]?.DateofPositiveResults?
      date = @["Facility"].DateofPositiveResults
      if date.match(/^20\d\d/)
        moment(@["Facility"].DateofPositiveResults).format("YYYY-MM-DD")
      else
        moment(@["Facility"].DateofPositiveResults, "DD-MM-YYYY").format("YYYY-MM-DD")

    notificationDate = if @["USSD Notification"]?
      @["USSD Notification"].date

    if dateOfPositiveResults? and notificationDate?
      Math.abs(moment(dateOfPositiveResults).diff(notificationDate, 'days'))


  timeFacilityNotified: =>
    if @["USSD Notification"]?
      @["USSD Notification"].date
    else
      null

  timeSinceFacilityNotified: =>
    timeFacilityNotified = @timeFacilityNotified()
    if timeFacilityNotified?
      moment().diff(timeFacilityNotified)
    else
      null

  hoursSinceFacilityNotified: =>
    timeSinceFacilityNotified = @timeSinceFacilityNotified()
    if timeSinceFacilityNotified?
      moment.duration(timeSinceFacilityNotified).asHours()
    else
      null

   moreThan24HoursSinceFacilityNotifed: =>
     @hoursSinceFacilityNotified() > 24

   moreThan48HoursSinceFacilityNotifed: =>
     @hoursSinceFacilityNotified() > 48

  timeFromSMSToCaseNotification: =>
    if @["Case Notification"]? and @["USSD Notification"]?
      return moment(@["Case Notification"]?.createdAt).diff(@["USSD Notification"]?.date)

  # Note the replace call to handle a bug that created lastModified entries with timezones
  timeFromCaseNotificationToCompleteFacility: =>
    if @["Facility"]?.complete is "true" and @["Case Notification"]?
      return moment(@["Facility"].lastModifiedAt.replace(/\+0\d:00/,"")).diff(@["Case Notification"]?.createdAt)

  daysFromCaseNotificationToCompleteFacility: =>
    if @["Facility"]?.complete is "true" and @["Case Notification"]?
      moment.duration(@timeFromCaseNotificationToCompleteFacility()).asDays()

  timeFromFacilityToCompleteHousehold: =>
    if @["Household"]?.complete is "true" and @["Facility"]?
      return moment(@["Household"].lastModifiedAt.replace(/\+0\d:00/,"")).diff(@["Facility"]?.lastModifiedAt)

  timeFromSMSToCompleteHousehold: =>
    if @["Household"]?.complete is "true" and @["USSD Notification"]?
      return moment(@["Household"].lastModifiedAt.replace(/\+0\d:00/,"")).diff(@["USSD Notification"]?.date)

  daysFromSMSToCompleteHousehold: =>
    if @["Household"]?.complete is "true" and @["USSD Notification"]?
      moment.duration(@timeFromSMSToCompleteHousehold()).asDays()

  spreadsheetRow: (question) =>
    console.error "Must call loadSpreadsheetHeader at least once before calling spreadsheetRow" unless Coconut.spreadsheetHeader?

    spreadsheetRowObjectForResult = (fields,result) ->
      if result?
        _(fields).map (field) =>
          if result[field]?
            if _.contains(Coconut.identifyingAttributes, field)
              return b64_sha1(result[field])
            else
              return result[field]
          else
            return ""
      else
        return null

    if question is "Household Members"
      _(@[question]).map (householdMemberResult) ->
        spreadsheetRowObjectForResult(Coconut.spreadsheetHeader[question], householdMemberResult)
    else
      spreadsheetRowObjectForResult(Coconut.spreadsheetHeader[question], @[question])

  spreadsheetRowString: (question) =>

    if question is "Household Members"
      _(@spreadsheetRow(question)).map (householdMembersRows) ->
        result = _(householdMembersRows).map (data) ->
          "\"#{data}\""
        .join(",")
        result += "--EOR--" if result isnt ""
      .join("")
    else
      result = _(@spreadsheetRow(question)).map (data) ->
        "\"#{data}\""
      .join(",")
      result += "--EOR--" if result isnt ""

  saveAndAddResultToCase: (result) =>
    if @[result.question]?
      console.error "#{result.question} already exists for:"
      console.error @
      return
    console.debug result
    resultQuestion = result.question
    Coconut.database.post result
    .then (result) =>
      console.log "saved"
      console.debug result
      @questions.push result.question
      @[result.question] = result
      console.debug @
      console.debug window.malariaCase
      Coconut.headerView.update()
      Coconut.showNotification( "#{resultQuestion} record created")
    .catch (error) ->
      console.error error

  createNextResult: =>
    @fetch
      error: -> console.error error
      success: =>
        if @["Household Members"] and @["Household Members"].length > 0
          console.log "Household Members exists, no result created"
          # Don't create anything
        else if @Household?.complete
          console.log "Creating Household members and neighbor households if necessary"
          @createHouseholdMembers()
          @createNeighborHouseholds()
        else if @Facility?.complete
          console.log "Creating Household"
          @createHousehold()
        else if @["Case Notification"]?.complete
          console.log "Creating Facility"
          @createFacility()
        _.delay(Coconut.menuView.render, 500)

  createFacility: =>
    @saveAndAddResultToCase
      question: "Facility"
      MalariaCaseID: @caseID
      FacilityName: @facility()
      Shehia: @shehia()
      collection: "result"
      createdAt: moment(new Date()).format(Coconut.config.get "date_format")
      lastModifiedAt: moment(new Date()).format(Coconut.config.get "date_format")

  createHousehold: =>
    @saveAndAddResultToCase
      question: "Household"
      Reasonforvisitinghousehold: "Index Case Household"
      MalariaCaseID: @caseID
      HeadOfHouseholdName: @Facility.HeadOfHouseholdName
      Shehia: @shehia()
      Village: @Facility.Village
      ShehaMjumbe: @Facility.ShehaMjumbe
      ContactMobilePatientRelative: @Facility.ContactMobilePatientRelative
      collection: "result"
      createdAt: moment(new Date()).format(Coconut.config.get "date_format")
      lastModifiedAt: moment(new Date()).format(Coconut.config.get "date_format")

  createHouseholdMembers: =>
    unless _(@questions).contains 'Household Members'
      # -1 because we don't need information for index case
      _(@Household.TotalNumberOfResidentsInTheHousehold-1).times =>
        result = {
          question: "Household Members"
          MalariaCaseID: @caseID
          HeadOfHouseholdName: @Household.HeadOfHouseholdName
          collection: "result"
          createdAt: moment(new Date()).format(Coconut.config.get "date_format")
          lastModifiedAt: moment(new Date()).format(Coconut.config.get "date_format")
        }

        Coconut.database.post result
        .then =>
          @questions.push result.question
          @[result.question] = [] unless @[result.question]
          @[result.question].push result
        .catch (error) ->
          console.error error

      Coconut.headerView.update()
      Coconut.showNotification( "Household member record(s) created")

  createNeighborHouseholds: =>
    # If there is more than one Household for this case, then Neighbor households must already have been created
    unless (_(@questions).filter (question) -> question is 'Household').length is 1
      _(@Household.NumberOfOtherHouseholdsWithin50StepsOfIndexCaseHousehold).times =>

        result = {
          ReasonForVisitingHousehold: "Index Case Neighbors"
          question: "Household"
          MalariaCaseID: @result.get "MalariaCaseID"
          Shehia: @result.get "Shehia"
          Village: @result.get "Village"
          ShehaMjumbe: @result.get "ShehaMjumbe"
          collection: "result"
          createdAt: moment(new Date()).format(Coconut.config.get "date_format")
          lastModifiedAt: moment(new Date()).format(Coconut.config.get "date_format")
        }

        Coconut.database.post result
        .then =>
          Coconut.headerView.update()
        .catch (error) ->
          console.error error

      Coconut.showNotification( "Neighbor Household created")

Case.loadSpreadsheetHeader = (options) ->
  if Coconut.spreadsheetHeader
    options.success()
  else
    Coconut.database.get "spreadsheet_header"
    .catch (error) ->
      console.error error
      options?.error()
    .then (result) =>
      Coconut.spreadsheetHeader = result.fields
      options.success()

Case.updateCaseSpreadsheetDocs = (options) ->

  # defaults used for first run
  caseSpreadsheetData = {_id: "CaseSpreadsheetData" }
  changeSequence = 0

  updateCaseSpreadsheetDocs = (changeSequence, caseSpreadsheetData) ->
    Case.updateCaseSpreadsheetDocsSince
      changeSequence: changeSequence
      error: (error) ->
        console.log "Error updating CaseSpreadsheetData:"
        console.log error
        options.error?()
      success: (numberCasesChanged,lastChangeSequenceProcessed) ->
        console.log "Updated CaseSpreadsheetData"
        caseSpreadsheetData.lastChangeSequenceProcessed = lastChangeSequenceProcessed
        console.log caseSpreadsheetData
        Coconut.database.saveDoc caseSpreadsheetData,
          success: ->
            console.log numberCasesChanged
            if numberCasesChanged > 0
              Case.updateCaseSpreadsheetDocs(options)  #recurse
            else
              options?.success?()

  Coconut.database.openDoc "CaseSpreadsheetData",
    success: (result) ->
      caseSpreadsheetData = result
      changeSequence = result.lastChangeSequenceProcessed
      updateCaseSpreadsheetDocs(changeSequence,caseSpreadsheetData)
    error: (error) ->
      console.log "Couldn't find 'CaseSpreadsheetData' using defaults: changeSequence: #{changeSequence}"
      updateCaseSpreadsheetDocs(changeSequence,caseSpreadsheetData)

Case.updateCaseSpreadsheetDocsSince = (options) ->
  Case.loadSpreadsheetHeader
    success: ->
      $.ajax
        url: "/#{Coconut.config.database_name()}/_changes"
        dataType: "json"
        data:
          since: options.changeSequence
          include_docs: true
          limit: 100000
        error: (error) =>
          console.log "Error downloading changes after #{options.changeSequence}:"
          console.log error
          options.error?(error)
        success: (changes) =>
          changedCases = _(changes.results).chain().map (change) ->
            change.doc.MalariaCaseID if change.doc.MalariaCaseID? and change.doc.question?
          .compact().uniq().value()
          lastChangeSequence = changes.results.pop()?.seq
          Case.updateSpreadsheetForCases
            caseIDs: changedCases
            error: (error) ->
              console.log "Error updating #{changedCases.length} cases, lastChangeSequence: #{lastChangeSequence}"
              console.log error
            success: ->
              console.log "Updated #{changedCases.length} cases, lastChangeSequence: #{lastChangeSequence}"
              options.success(changedCases.length, lastChangeSequence)



Case.updateSpreadsheetForCases = (options) ->
  docsToSave = []
  questions = "USSD Notification,Case Notification,Facility,Household,Household Members".split(",")
  options.success() if options.caseIDs.length is 0

  finished = _.after options.caseIDs.length, ->
    Coconut.database.bulkSave {docs:docsToSave},
      error: (error) -> console.log error
      success: -> options.success()

  _(options.caseIDs).each (caseID) ->
    malariaCase = new Case
      caseID: caseID
    malariaCase.fetch
      error: (error) ->
        console.log error
      success: ->

        docId = "spreadsheet_row_#{caseID}"
        spreadsheet_row_doc = {_id: docId}
        Coconut.database.openDoc docId,
          success: (result) ->
            spreadsheet_row_doc = result
            _(questions).each (question) ->
              spreadsheet_row_doc[question] = malariaCase.spreadsheetRowString(question)
            docsToSave.push spreadsheet_row_doc
            finished()
          error: ->
            _(questions).each (question) ->
              spreadsheet_row_doc[question] = malariaCase.spreadsheetRowString(question)
            docsToSave.push spreadsheet_row_doc
            finished()

Case.setup = =>
  new Promise (resolve) =>

    for docId in ["shehias_high_risk","shehias_received_irs"]
      await Coconut.database.get docId
      .catch (error) -> console.error JSON.stringify error
      .then (result) ->
        Coconut[docId] = result
        Promise.resolve()

    designDocs = {
      cases: (doc) ->
        emit(doc.MalariaCaseID, null) if doc.MalariaCaseID
        emit(doc.caseid, null) if doc.caseid

      casesWithSummaryData: (doc) ->
        if doc.MalariaCaseID
          date = doc.DateofPositiveResults or doc.lastModifiedAt
          match = date.match(/^(\d\d).(\d\d).(2\d\d\d)/)
          if match?
            date = "#{match[3]}-#{match[2]}-#{match[1]}"

          if doc.transferred?
            lastTransfer = doc.transferred[doc.transferred.length-1]

          if date.match(/^2\d\d\d\-\d\d-\d\d/)
            emit date, [doc.MalariaCaseID,doc.question,doc.complete,lastTransfer]

        if doc.caseid
          if document.transferred?
            lastTransfer = doc.transferred[doc.transferred.length-1]
          if doc.date.match(/^2\d\d\d\-\d\d-\d\d/)
            emit doc.date, [doc.caseid, "Facility Notification", null, lastTransfer]

    }

    for name, designDocFunction of designDocs
      designDoc = Utils.createDesignDoc name, designDocFunction
      await Coconut.database.upsert designDoc._id, (existingDoc) =>
        return false if _(designDoc.views).isEqual(existingDoc?.views)
        console.log "Creating Case view: #{name}"
        designDoc
      .catch (error) => 
        console.error error
    resolve()


module.exports = Case
