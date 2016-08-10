class Sync extends Backbone.Model
  initialize: ->
    @set
      _id: "SyncLog"

  target: -> Coconut.config.cloud_url()

  last_send: =>
    return @get("last_send_result")

  was_last_send_successful: =>
    return not @get("last_send_error") or false

  last_send_time: =>
    result = @get("last_send_time")
    if result
      return moment(@get("last_send_time")).fromNow()
    else
      return "never"

  was_last_get_successful: =>
    return @get "last_get_success"

  last_get_time: =>
    result = @get("last_get_time")
    if result
      return moment(@get("last_get_time")).fromNow()
    else
      return "never"

  backgroundSync: =>
    @lastSuccessfulSync = moment("2000-01-01") unless @lastSuccessfulSync? # TODO save this in PouchDB or use existing one
    console.log "backgroundSync called at #{moment().toString()} lastSuccessfulSync was #{@lastSuccessfulSync.toString()}}"
    minimumMinutesBetweenSync = 15

    _.delay @backgroundSync, minimumMinutesBetweenSync*60*1000

    Coconut.questions.each (question) =>
      Coconut.database.query "results",
        startkey: [question.id,true,@lastSuccessfulSync.format(Coconut.config.get("date_format"))]
        endkey: [question.id,true,{}]
      .then (result) =>
        if result.rows.length > 0 and moment().diff(@lastSuccessfulSync,'minutes') > minimumMinutesBetweenSync
          console.log "Initiating background sync"
          $("div#log").hide()
          @sendToCloud
            completeResultsOnly: true
            error: (error) ->
              console.log "Error: #{JSON.stringify error}"
              $("div#log").html("")
              $("div#log").show()
            success: =>
              @lastSuccessfulSync = moment()
              $("div#log").html("")
              $("div#log").show()
        else
          console.log "No new results for #{question.id} so not syncing"
  

    # Check if there are new results
    # Send results if new results and timeout

  checkForInternet: (options) =>
    @log "Checking for internet. (Is #{Coconut.config.cloud_url()} is reachable?) Please wait."
    Coconut.cloudDatabase.info()
    .catch (error) =>
      @log "ERROR! #{Coconut.config.cloud_url()} is not reachable. Do you have enough airtime? Are you on WIFI?  Either the internet is not working or the site is down: #{JSON.stringify(error)}"
      options.error()
      @save
        last_send_error: true
    .then (result) =>
        @log "#{Coconut.config.cloud_url()} is reachable, so internet is available."
        options.success()

  sendToCloud: (options) =>
    $("#status").html "Sending data..."
    @fetch
      error: (error) => @log "Unable to fetch Sync doc: #{JSON.stringify(error)}"
      success: =>
        @checkForInternet
          error: (error) ->
            console.error "No internet"
            options?.error?(error)
          success: =>
            @log "Creating list of all results on the tablet. Please wait."
            Coconut.database.query "results"
            .catch (error) =>
              console.error error
              @log "Could not retrieve list of results: #{JSON.stringify(error)}"
              options.error()
              @save
                last_send_error: true
            .then (result) =>
              resultIDs = if options.completeResultsOnly? and options.completeResultsOnly is true
                _.chain(result.rows)
                .filter (row) ->
                  row.key[1] is true # Only get complete results
                .pluck("id").value()
              else
                _.pluck result.rows, "id"

              @log "Synchronizing #{resultIDs.length} results. Please wait."

              Coconut.database.replicate.to Coconut.config.cloud_url_with_credentials(),
                doc_ids: resultIDs
              .on 'complete', (info) =>
                @log "Success! Send data finished: created, updated or deleted #{info.docs_written} results on the server."
                @save
                  last_send_result: result
                  last_send_error: false
                  last_send_time: new Date().getTime()
                options.success()
              .on 'error', (error) ->
                console.error error
                options.error(error)


  log: (message) =>
    console.log message
    #Coconut.debug message

  getFromCloud: (options) =>
    console.debug options
    $("#status").html "Getting data..."
    @fetch
      error: (error) => @log "Unable to fetch Sync doc: #{JSON.stringify(error)}"
      success: =>
        @checkForInternet
          error: ->
            options.error?(error)
          success: =>
            @fetch
              success: =>
                @getNewNotifications
                  success: =>
                    # Get Household data for all households with shehias in user's district.
                    @log "Updating users and forms. Please wait."
                    @replicateApplicationDocs
                      error: (error) =>
                        $.couch.logout()
                        @log "ERROR updating application: #{JSON.stringify(error)}"
                        @save
                          last_get_success: false
                        options?.error?(error)
                      success: =>
                        @transferCasesIn
                          success: =>
                            @fetch
                              error: (error) => @log "Unable to fetch Sync doc: #{JSON.stringify(error)}"
                              success: =>
                                @save
                                  last_get_success: true
                                  last_get_time: new Date().getTime()
                                console.debug options
                                options?.success?()
                                _.delay ->
                                  document.location.reload()
                                , 5000


  replicateApplicationDocs: (options) =>
    @checkForInternet
      error: (error) -> options?.error?(error)
      success: =>
        @log "Getting list of application documents to replicate"
        # Updating design_doc, users & forms
        Coconut.cloudDatabase.query "docIDsForUpdating"
        .catch (error) ->  options.error?(error)
        .then (result) =>
          doc_ids = _(result.rows).chain().pluck("id").without("_design/coconut").uniq().value()
          @log "Updating #{doc_ids.length} docs <small>(users and forms: #{doc_ids.join(', ')})</small>. Please wait."
          Coconut.database.replicate.from Coconut.config.cloud_url_with_credentials(),
            doc_ids: doc_ids
          .on 'change', (info) =>
            console.log info
          .on 'complete', (info) =>
            console.log "COMPLETE"
            console.log info
            Coconut.syncPlugins
              success: ->
                options?.success?()
              error: -> options?.error?()
          .on 'error', (error) =>
            console.error error
            @log "Error while updating application documents: #{JSON.stringify error}"
            options.error?(error)

  getNewNotifications: (options) ->
    @log "Looking for most recent Case Notification on tablet. Please wait."
    Coconut.database.query "rawNotificationsConvertedToCaseNotifications",
      descending: true
      include_docs: true
      limit: 1
    .catch (error) => @log "Unable to find the the most recent case notification: #{JSON.stringify(error)}"
    .then (result) =>
      mostRecentNotification = result.rows?[0]?.doc.date
      if mostRecentNotification? and moment(mostRecentNotification).isBefore((new moment).subtract(3,'weeks'))
        dateToStartLooking = mostRecentNotification
      else
        dateToStartLooking = (new moment).subtract(3,'weeks').format(Coconut.config.get("date_format"))


      Coconut.database.get "district_language_mapping"
      .catch (error) -> alert "Couldn't find english_to_swahili map: #{JSON.stringify result}"
      .then (result) =>
        district_language_mapping = result.english_to_swahili
    
        @log "Looking for USSD notifications without Case Notifications after #{dateToStartLooking}. Please wait."

        Coconut.cloudDatabase.query "rawNotificationsNotConvertedToCaseNotifications",
          include_docs: true
          startkey: dateToStartLooking
          skip: 1
        .catch (error) => @log "ERROR, could not download USSD notifications: #{JSON.stringify error}"
        .then (result) =>
          currentUserDistrict = Coconut.currentUser.get("district")

          if district_language_mapping[currentUserDistrict]?
            currentUserDistrict = district_language_mapping[currentUserDistrict]

          @log "Found #{result.rows.length} USSD notifications. Filtering for USSD notifications for district:  #{currentUserDistrict}. Please wait."
          _.each result.rows, (row) =>
            notification = row.doc

            districtForNotification = notification.facility_district

            if district_language_mapping[districtForNotification]?
              districtForNotification = district_language_mapping[districtForNotification]

            # Try and fix shehia, district and facility names. Use levenshein distance

            unless _(GeoHierarchy.allDistricts()).contains districtForNotification
              @log "#{districtForNotification} not valid district, trying to use health facility: #{notification.hf} to identify district"
              if FacilityHierarchy.getDistrict(notification.hf)?
                districtForNotification = FacilityHierarchy.getDistrict(notification.hf)
                @log "Using district: #{districtForNotification} indicated by health facility."
              else
                @log "Can't find a valid district for health facility: #{notification.hf}"
              # Check it again  
              unless _(GeoHierarchy.allDistricts()).contains districtForNotification
                @log "#{districtForNotification} still not valid district, trying to use shehia name to identify district: #{notification.shehia}"
                if GeoHierarchy.findOneShehia(notification.shehia)?
                  districtForNotification = GeoHierarchy.findOneShehia(notification.shehia).DISTRCT
                  @log "Using district: #{districtForNotification} indicated by shehia."
                else
                  @log "Can't find a valid district using shehia for notification: #{JSON.stringify notification}."

            if districtForNotification is currentUserDistrict

              if confirm "Accept new case? Facility: #{notification.hf}, Shehia: #{notification.shehia}, Name: #{notification.name}, ID: #{notification.caseid}, date: #{notification.date}. You may need to coordinate with another DMSO."
                @convertNotificationToCaseNotification(notification)
                @log "Case notification #{notification.caseid}, accepted by #{User.currentUser.username()}"
              else
                @log "Case notification #{notification.caseid}, not accepted by #{User.currentUser.username()}"
          options.success?()

  convertNotificationToCaseNotification: (notification) =>
    result = new Result
      question: "Case Notification"
      MalariaCaseID: notification.caseid
      FacilityName: notification.hf
      Shehia: notification.shehia
      Name: notification.name
    result.save null,
      error: (error) =>
        @log "Could not save #{result.toJSON()}:  #{JSON.stringify error}"
      success: (error) =>
        notification.hasCaseNotification = true
        $.couch.db(Coconut.config.database_name()).saveDoc notification,
          error: (error) => @log "Could not save notification #{JSON.stringify(notification)} : #{JSON.stringify(error)}"
          success: =>
            @log "Created new case notification #{result.get "MalariaCaseID"} for patient #{result.get "Name"} at #{result.get "FacilityName"}"
            doc_ids = [result.get("_id"), notification._id ]
            # Sync results back to the 
            $.couch.replicate(
              Coconut.config.database_name(),
              Coconut.config.cloud_url_with_credentials(),
                error: (error) =>
                  @log "Error replicating #{doc_ids} back to server: #{JSON.stringify error}"
                success: (result) =>
                  @log "Sent docs: #{doc_ids}"
                  @save
                    last_send_result: result
                    last_send_error: false
                    last_send_time: new Date().getTime()
              , doc_ids: doc_ids
            )

  transferCasesIn: (options) =>
    $("#status").html "Checking for transfer cases..."
    @log "Checking cloud server for cases transferred to #{Coconut.currentUser.username()}"
    Coconut.cloudDatabase.query "resultsAndNotificationsNotReceivedByTargetUser",
      include_docs: true
      key: Coconut.currentUser.get("_id")
    .catch (error) =>
      @log "Could not retrieve list of resultsAndNotificationsNotReceivedByTargetUser for #{Coconut.currentUser.get("_id")}"
      @log error
      console.error error
      options?.error(error)
      @save
        last_send_error: true
    .then (result) =>
      cases = {}
      _(result.rows).each (row) ->
        caseId = row.value[1]
        cases[caseId] = [] unless cases[caseId]
        cases[caseId].push row.doc

      caseSuccessHandler = _.after(_(cases).size(), options?.success)

      if _(cases).isEmpty()
        @log "No cases to transfer."
        caseSuccessHandler()

      _(cases).each (resultDocs) =>
        malariaCase = new Case()
        malariaCase.loadFromResultDocs(resultDocs)
        caseId = malariaCase.MalariaCaseID()
        if not confirm "Accept transfer case #{caseId} #{malariaCase.indexCasePatientName()} from facility #{malariaCase.facility()} in #{malariaCase.district()}?"
          caseSuccessHandler()
        else
          resultsSuccessHandler = _.after resultDocs.length, caseSuccessHandler()

          _(resultDocs).each (resultDoc) =>
            resultDoc.transferred[resultDoc.transferred.length - 1].received = true
            $.couch.db(Coconut.config.database_name()).saveDoc resultDoc,
              error: (error) =>
                @log "ERROR: #{caseId}: #{resultDoc.question or "Notification"} could not be saved on tablet: #{JSON.stringify error}"
              success: (success) =>
                @log "#{caseId}: #{resultDoc.question or "Notification"} saved on tablet"

                $.couch.replicate(
                  Coconut.config.database_name(),
                  Coconut.config.cloud_url_with_credentials(),
                    success: =>
                      @log "#{caseId}: #{resultDoc.question or "Notification"} marked as received in cloud"
                      resultsSuccessHandler()
                    error: (error) =>
                      @log "ERROR: #{caseId}: #{resultDoc.question or "Notification"} could not be marked as received in cloud. In case of conflict report to ZaMEP, otherwise press Get Data again. #{JSON.stringify error}"
                  ,
                    doc_ids: [resultDoc._id]
                )


module.exports = Sync


