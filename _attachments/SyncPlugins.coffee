Dialog = require './js-libraries/modal-dialog'

Sync::getFromCloud = (options) ->
  $("#status").html "Getting data..."
  @fetch
    error: (error) =>
      @log "Unable to fetch Sync doc: #{JSON.stringify(error)}"
      options?.error?(error)
    success: =>
      Coconut.checkForInternet
        error: (error)->
          @save
            last_send_error: true
          options?.error?(error)
          Coconut.noInternet()
        success: =>
          @fetch
            success: =>
              $("#status").html "Getting new notifications..."
              @getNewNotifications
                success: =>
                  $("#status").html "Updating users and forms. Please wait."
                  @replicateApplicationDocs
                    error: (error) =>
                      @log "ERROR updating application: #{JSON.stringify(error)}"
                      @save
                        last_get_success: false
                      options?.error?(error)
                    success: =>
                      @transferCasesIn()
                      .catch (error) => @log error
                      .then =>

                        @fetch
                          error: (error) => @log "Unable to fetch Sync doc: #{JSON.stringify(error)}"
                          success: =>
                            @save
                              last_get_success: true
                              last_get_time: new Date().getTime()
                            options?.success?()

Sync::getNewNotifications = (options) ->
  new Promise (resolve, reject) =>
    @log "Looking for most recent Case Notification on device. Please wait."
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
        dateToStartLooking = (new moment).subtract(3,'months').format(Coconut.config.get("date_format"))


      Coconut.database.get "district_language_mapping"
      .catch (error) -> alert "Couldn't find english_to_swahili map: #{JSON.stringify result}"
      .then (result) =>
        district_language_mapping = result.english_to_swahili

        @log "Looking for USSD notifications without Case Notifications after #{dateToStartLooking}. Please wait."

        Coconut.cloudDB.query "rawNotificationsNotConvertedToCaseNotifications",
          include_docs: true
          startkey: dateToStartLooking
          skip: 1
        .catch (error) => @log "ERROR, could not download USSD notifications: #{JSON.stringify error}"
        .then (result) =>
          currentUserDistrict = Coconut.currentUser.get("district")

          if district_language_mapping[currentUserDistrict]?
            currentUserDistrict = district_language_mapping[currentUserDistrict]

          @log "Found #{result.rows?.length} USSD notifications. Filtering for USSD notifications for district:  #{currentUserDistrict}. Please wait."
          acceptedNotificationIds = []
          for row in result.rows
            notification = row.doc

            districtForNotification = notification.facility_district

            if district_language_mapping[districtForNotification]?
              districtForNotification = district_language_mapping[districtForNotification]

            # Try and fix shehia, district and facility names. Use levenshein distance

            unless _(GeoHierarchy.allDistricts()).contains districtForNotification
              @log "#{districtForNotification} not valid district, trying to use health facility: #{notification.hf} to identify district"
              if GeoHierarchy.getDistrict(notification.hf)?
                districtForNotification = GeoHierarchy.getDistrict(notification.hf)
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
                acceptedNotificationIds.push(notification._id)
                @log "Case notification #{notification.caseid}, accepted by #{Coconut.currentUser.username()}"
              else
                @log "Case notification #{notification.caseid}, not accepted by #{Coconut.currentUser.username()}"
          @convertNotificationsToCaseNotification(acceptedNotificationIds).then =>
            options.success?()

Sync::convertNotificationsToCaseNotification = (acceptedNotificationIds) ->
  new Promise (resolve, reject) =>
    console.log "Accepted: #{acceptedNotificationIds.join(',')}"

    return resolve() if _(acceptedNotificationIds).isEmpty()

    newCaseNotificationIds = []
    for notificationId in acceptedNotificationIds
      await Coconut.cloudDB.get notificationId
      .then (notification) =>
        result = new Result
          question: "Case Notification"
          MalariaCaseID: notification.caseid
          FacilityName: notification.hf
          Shehia: notification.shehia
          Name: notification.name
          NotificationDocumentID: notificationId
        result.save()
        .catch (error) =>
          @log "Could not save #{result.toJSON()}:  #{JSON.stringify error}"
        .then =>
          notification.hasCaseNotification = true
          notification.caseNotification = result.get "_id"
          Coconut.cloudDB.put notification
          .catch (error) =>
            alert "Error marking notification as accepted (someone else may have accepted it), canceling acceptance of case #{notification.caseid}"
            result.destroy() #Ideally would use callbacks or promises here but they don't work well
          .then =>
            newCaseNotificationIds.push result.get "_id"


    Coconut.database.replicate.to Coconut.cloudDB,
      doc_ids: newCaseNotificationIds
    .catch (error) =>
      @log "Error replicating #{newCaseNotificationIds} back to server: #{JSON.stringify error}"
    .then (result) =>
      @log "Sent docs: #{newCaseNotificationIds}"
      @save
        last_send_result: result
        last_send_error: false
        last_send_time: new Date().getTime()
      resolve()

Sync::transferCasesIn =  (options) ->
  console.error "callback for transferCasesIn will be deprecated" if options?
  new Promise (resolve, reject) =>
    $("#status").html "Checking for transfer cases..."
    @log "Checking cloud server for cases transferred to #{Coconut.currentUser.username()}"
    Coconut.cloudDB.query "resultsAndNotificationsNotReceivedByTargetUser",
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
      transferCases = {}
      _(result.rows).each (row) ->
        caseId = row.value[1]
        (transferCases[caseId] ?= []).push row.doc

      if _(transferCases).isEmpty()
        @log "No cases to transfer."
        options?.success()
        resolve()

      for caseID, caseResultDocs of transferCases
        transferCase = new Case()
        transferCase.loadFromResultDocs(caseResultDocs)
        caseId = transferCase.MalariaCaseID()
        if confirm "Accept transfer case #{caseId} #{transferCase.indexCasePatientName()} from facility #{transferCase.facility()} in #{transferCase.district()}?"
          caseResultIds = _(caseResultDocs).pluck "_id"
          await Coconut.cloudDB.replicate.to Coconut.database,
            doc_ids: caseResultIds
          .catch (error) => 
            console.error error
            @log "Failed to replicate from cloud a transfered case: #{transferCase.MalariaCaseID()}"
            throw "Failed to replicate from cloud a transfered case: #{transferCase.MalariaCaseID()}"
          .then =>
            for caseResultId in caseResultIds
              await Coconut.database.upsert caseResultId, (caseResultDoc) =>
                caseResultDoc.transferred[caseResultDoc.transferred.length - 1].received = true
                caseResultDoc
            Coconut.cloudDB.replicate.from Coconut.database,
              doc_ids: caseResultIds
            .catch (error) => 
              console.error error
              @log "Failed to replicate to cloud a transfered case: #{transferCase.MalariaCaseID()}"
              throw "Failed to replicate to cloud a transfered case: #{transferCase.MalariaCaseID()}"
            .then (replicationResult) =>
              console.log replicationResult
              @log "#{caseId} (#{caseResultIds.join()}): saved on device and updated in cloud"
              Promise.resolve()
      options?.success()
      resolve()