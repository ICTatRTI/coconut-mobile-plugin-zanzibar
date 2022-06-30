Dialog = require './js-libraries/modal-dialog'

Sync::getFromCloud = (options) ->
  $("#status").append "<br/>Getting data..."
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
              $("#status").append "<br/>Updating users and forms. Please wait."
              @replicateApplicationDocs
                error: (error) =>
                  @log "ERROR updating application: #{JSON.stringify(error)}"
                  @save
                    last_get_success: false
                  options?.error?(error)
                success: =>
                  $("#status").append "<br/>Getting new notifications..."
                  @getNewNotifications
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

    $("#status").append "<br/>Looking for new facility notifications..."

    notificationsForUsersDistricts = await Coconut.notificationsDB.query "unacceptedNotificationsByDateAndDistrict",
      include_docs: true
    .then (result) =>
      currentUserDistricts = [Coconut.currentUser.district()].filter (district) => 
        GeoHierarchy.validDistrict(district)

      Promise.resolve(
        result.rows.reduce (relevantNotifications, row) => 
          district = row.key[1]
          relevantNotifications.push(row.doc) if currentUserDistricts.includes(district)
          relevantNotifications
        , []
      )

    acceptedNotificationIds = []

    for notification in notificationsForUsersDistricts
      DistrictForFacility = notification.facility_district or notification["Facility District"] or notification["facility-district"]
      FacilityName = notification.hf or notification.Facility or notification["facility"]
      Shehia = notification.shehia or notification["Patient Shehia"] or notification["shehia"]
      if notification["Date of Positive Result"] and notification["Time of Positive Result"]
        DateAndTimeOfPositiveResults = "#{notification["Date of Positive Result"]} #{notification["Time of Positive Result"]}" 
      else if notification["date-and-time-of-positive-results"]
        DateAndTimeOfPositiveResults = notification["date-and-time-of-positive-results"]
      else
        DateAndTimeOfPositiveResults = notification["Notification Creation Datetime"]

      if confirm "Accept new case? Facility: #{FacilityName} (#{DistrictForFacility}), Patient Shehia: #{Shehia}, Name: #{notification["last-name"]}, ID: #{notification._id?.split("-").pop()}, Date and time of positive results: #{DateAndTimeOfPositiveResults}. You may need to coordinate with another DMSO."
        acceptedNotificationIds.push(notification._id)
        $("#status").append "<br/>Case notification #{notification._id}, accepted by #{Coconut.currentUser.username()}"

    await @convertNotificationsToCaseNotification(acceptedNotificationIds, Coconut.notificationsDB)
    await @convertNotificationsToFacility(acceptedNotificationIds, Coconut.notificationsDB)
    options?.success()

Sync::convertNotificationsToCaseNotification = (acceptedNotificationIds, notificationsDB = Coconut.cloudDB) ->
  new Promise (resolve, reject) =>
    console.log "Accepted: #{acceptedNotificationIds.join(',')}"

    return resolve() if _(acceptedNotificationIds).isEmpty()

    newCaseNotificationIds = []
    for notificationId in acceptedNotificationIds
      await notificationsDB.get notificationId
      .then (notification) =>
        result = new Result
          question: "Case Notification"
          MalariaCaseID: notification.caseid or notification._id?.split("-").pop() #Get everything after last - to get ID part of _id
          DistrictForFacility: notification.facility_district or notification["Facility District"] or notification["facility-district"]
          FacilityName: notification.hf or notification.Facility or notification["facility"]
          DistrictForShehia: notification["Patient District"] or notification["district-for-shehia"]
          Shehia: notification.shehia or notification["Patient Shehia"] or notification["shehia"]
          Name: notification.name or notification["Patient Name"] or notification["last-name"]
          Sex: notification.Sex or notification["sex"]
          Age: notification.Age or notification["age"]
          AgeInYearsMonthsDays: notification["Age in Years/Months/Days"] or notification["age-in-years-months-days"]
          DateAndTimeOfPositiveResults: "#{notification["Date of Positive Result"]}T#{notification["Time of Positive Result"]}" or notification["date-and-time-of-positive-results"]
          CaseCategory: notification["Case Category"] or notification["case-classification-categories"]
          NotificationDocumentID: notificationId
          complete: true
        result.save()
        .catch (error) =>
          @log "Could not save #{result.toJSON()}:  #{JSON.stringify error}"
        .then =>
          notification.hasCaseNotification = true
          notification.caseNotification = result.get "_id"
          notificationsDB.put notification
          .catch (error) =>
            alert "Error marking notification as accepted (someone else may have accepted it), canceling acceptance of case #{notification.caseid}"
            result.destroy() #Ideally would use callbacks or promises here but they don't work well
          .then =>
            newCaseNotificationIds.push result.get "_id"

    Coconut.database.replicate.to Coconut.cloudDB,
      doc_ids: newCaseNotificationIds
    .catch (error) =>
      $("#status").append "<br/>Error replicating #{newCaseNotificationIds} back to server: #{JSON.stringify error}"
    .then (result) =>
      $("#status").append "<br/>Sent docs: #{newCaseNotificationIds}"
      @save
        last_send_result: result
        last_send_error: false
        last_send_time: new Date().getTime()
    resolve()

Sync::convertNotificationsToFacility = (acceptedNotificationIds, notificationsDB = Coconut.cloudDB) ->
  new Promise (resolve, reject) =>
    console.log "Accepted: #{acceptedNotificationIds.join(',')}"

    return resolve() if _(acceptedNotificationIds).isEmpty()

    for notificationId in acceptedNotificationIds
      await notificationsDB.get notificationId
      .then (notification) =>
        result = new Result
          question: "Facility"
          MalariaCaseID: notification.caseid or notification._id?.split("-").pop() #Get everything after last - to get ID part of _id
          DistrictForFacility: notification["facility-district"]
          FacilityName: notification["facility"]
          MalariaTestPerformed: notification["malaria-test-performed"]
          DateAndTimeOfPositiveResults: notification["date-and-time-of-positive-results"]
          MalariaMrdtTestResults: notification["malaria-mrdt-test-results"] or ""
          MalariaMicroscopyTestResults: notification["malaria-microscopy-test-results"] or ""
          ParasitesDensityPerL: notification["parasites-density-per-l"] or ""
          ReferenceInOpdRegister: notification["reference-in-opd-register"]
          FirstName: notification["first-name"] 
          MiddleName: notification["middle-name"] or ""
          LastName: notification["last-name"]
          Age: notification["age"]
          AgeInYearsMonthsDays: notification["age-in-years-months-days"]
          Sex: notification["sex"]
          DistrictForShehia: notification["district-for-shehia"]
          Shehia: notification["shehia"]
          Village: notification["village"]
          ShehaMjumbe: notification["sheha-mjumbe"]
          HeadOfHouseholdName: notification["head-of-household-name"]
          ContactMobilePatientRelative: notification["contact-mobile-patient-relative"]
          TypeOfTreatmentPrescribed: notification["treatment-prescribed"]
          AsaqDoseAndStrength: notification["asaq-dose-and-strength"] or ""
          AluDoseAndStrength: notification["alu-dose-and-strength"] or ""
          InjectionArtesunateDoseAndStrength: notification["injection-artesunate-dose-and-strength"] or ""
          InjectionArtemetherDoseAndStrength: notification["injection-artemether-dose-and-strength"] or ""
          DuoCotexinDoseAndStrength: notification["duo-cotexin-dose-and-strength"]
          ClindamycinBaseDoseAndStrength: notification["clindamycin-base-dose-and-strength"] or ""
          QuinineSulfateDoseAndStrength:  notification["quinine-sulfate-dose-and-strength"] or ""
          OtherAntimalarialGiven: notification["other-antimalarial-given"] or ""
          IfYesListAllPlacesTravelled: notification["if-yes-list-all-places-travelled"] or ""
          PrimaquineDose: notification["primaquine-dose"] or ""
          TravelledOvernightInPastMonth: notification["travelled-overnight-in-past-month"]
          CaseCategory: notification["case-classification-categories"]
        result.save()
        .catch (error) =>
          @log "Could not save #{result.toJSON()}:  #{JSON.stringify error}"
        .then =>
          resolve()

Sync::transferCasesIn =  (options) ->
  console.error "callback for transferCasesIn will be deprecated" if options?
  new Promise (resolve, reject) =>
    $("#status").append "<br/>Checking for transfer cases..."
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
        return resolve()

      for caseID, caseResultDocs of transferCases
        transferCase = new Case()
        transferCase.loadFromResultDocs(caseResultDocs)
        console.log transferCase
        console.log "ZZZZ"
        caseId = transferCase.MalariaCaseID()
        if confirm "Accept transfer case #{caseId} #{transferCase.indexCasePatientName()} from facility #{transferCase.facility()} in #{transferCase.district()}?"

          # Due to bug that breaks replication for crypto pouch documents when they are replicated in, edited and replicated back, we have to (see failCrypto.coffee)
          # 
          # 1. Delete them on the cloud database
          # 2. Create new docs without _rev numbers (this is the workaround hack which forces replication)
          # 3. Add the transfered information
          # 4. Save them as new local documents
          # 5. Replicate them to the cloud database
          caseResultIds = _(caseResultDocs).pluck "_id"
          result = await Coconut.cloudDB.allDocs
            keys: caseResultIds
            include_docs: true
          .catch (error) => console.error error

          docsToSave = for row in result.rows
            await Coconut.cloudDB.remove(row.doc) #1
            delete row.doc._rev #2
            row.doc.transferred[row.doc.transferred.length - 1].received = true #3
            row.doc

          await Coconut.database.bulkDocs docsToSave
          .catch (error) => console.error error

          await Coconut.database.replicate.to Coconut.cloudDB,
            doc_ids: caseResultIds
          .catch (error) => 
            console.error error
            @log "Failed to replicate to cloud a transfered case: #{transferCase.MalariaCaseID()}"
            throw "Failed to replicate to cloud a transfered case: #{transferCase.MalariaCaseID()}"

      options?.success()
      resolve()


      ###
      await Coconut.cloudDB.replicate.to Coconut.database,
        doc_ids: caseResultIds
      .catch (error) => 
          .catch (error) => 
      .catch (error) => 
          .catch (error) => 
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
            .catch (error) => 
        .catch (error) => 
            .catch (error) => 
        .catch (error) => 
          console.error error
          @log "Failed to replicate to cloud a transfered case: #{transferCase.MalariaCaseID()}"
          throw "Failed to replicate to cloud a transfered case: #{transferCase.MalariaCaseID()}"
        .then (replicationResult) =>
          console.log replicationResult
          @log "#{caseId} (#{caseResultIds.join()}): saved on device and updated in cloud"
          Promise.resolve()
      ###
      #
      #
      #

Sync::sendToCloud =  (options) ->
  @fetch
    error: (error) =>
      @log "Unable to fetch Sync doc: #{JSON.stringify(error)}"
      options?.error?(error)
    success: =>
      Coconut.checkForInternet
        error: (error) =>
          @save
            last_send_error: true
          options?.error?(error)
          Coconut.noInternet()
        success: =>
          $("#status").append "<br/>Creating list of all results on the mobile device. Please wait."
          await Coconut.database.query "results", {},
            (error,result) =>
              if error
                console.log "Could not retrieve list of results: #{JSON.stringify(error)}"
                $("#status").append "<br/>ERROR: Could not retrieve list of results: #{JSON.stringify(error)}"
                options?.error?(error)
                @save
                  last_send_error: true
              else
                resultIDs = if options.completeResultsOnly? and options.completeResultsOnly is true
                  _.chain(result.rows)
                  .filter (row) ->
                    row.key[1] is true # Only get complete results
                  .pluck("id").value()
                else
                  _.pluck result.rows, "id"

                $("#status").append "<br/>Synchronizing #{resultIDs.length} results. Please wait."

                Coconut.database.replicate.to Coconut.cloudDB,
                  doc_ids: resultIDs
                  timeout: 60000
                  batch_size: 20
                .on 'complete', (info) =>
                  @log "Success! Send data finished: created, updated or deleted #{info.docs_written} results on the server."
                  alert "Success! Send data finished: created, updated or deleted #{info.docs_written} results on the server."
                  @save
                    last_send_result: result
                    last_send_error: false
                    last_send_time: new Date().getTime()
                  Promise.resolve()
                .on 'error', (error) ->
                  $("#status").append "<br/>ERROR: While replicating results to server: #{JSON.stringify error}"
                  console.error error
                  Promise.reject()
                  options.error(error)
                .on 'change', (changes) =>
                  $("#status").append "<br/>Sync update: #{JSON.stringify changes}"


          ###
          # EXAMPLE ACTION ON SYNC
          millisecondsSinceBeginningOf2021 = moment().format('x') - moment("2021-01-01").format('x')
          millisecondsEncodedAsBase32 = bases.toBase32(millisecondsSinceBeginningOf2021)

          Coconut.database.put
            _id: "syncAction_#{Coconut.instanceId}_#{millisecondsEncodedAsBase32}"
            action: "await fetch('https://lapq907iz0.execute-api.us-east-1.amazonaws.com/default/corsProxy?url=https://example.com')"
            description: "Test Action"
          ###

          @log "Checking for outstanding actions on sync"
          await Coconut.database.allDocs
            startkey: "syncAction_"
            endkey: "syncAction_\uf000"
            include_docs: true
          .then (result) =>
            for row in result.rows
              unless row.doc.complete
                $("#status").append "<br/>Found sync action that needs to be done: #{JSON.stringify row.doc.action}"
                console.log "Found sync action:"
                console.log row.doc.action
                # Format for coffeescript spacing
                action = row.doc.action.replace(/\n/g,"\n      ")
      
                codeToEvalAsPromiseReturningFunction = """
->
new Promise (response) ->
  response(
    #{action}
  )
"""

                try
                  evaldFunction = await CoffeeScript.eval(codeToEvalAsPromiseReturningFunction, {bare:true})

                  # Now execute the function
                  await evaldFunction()
                  .then (result) =>
                    console.log "RESULT:"
                    console.log result
                    row.doc.complete = true
                    row.doc.result = result
                    row.doc.completeTime = moment().format("YYYY-MM-DD HH:mm:ss")
                  .catch (error) =>
                    $("#status").append "Error on sync action: #{JSON.stringify error}"
                    console.error "Error on this sync action:"
                    console.error codeToEvalAsPromiseReturningFunction
                    console.error "Here's the error"
                    console.error error

                    row.doc.complete = false
                    row.doc.error or= []
                    row.doc.error.push error
                  await Coconut.database.put row.doc

                catch error
                  console.error error
            Promise.resolve()
          Promise.resolve()
          options?.success?()



