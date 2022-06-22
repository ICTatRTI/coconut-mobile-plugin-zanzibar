Dialog = require './js-libraries/modal-dialog'

class TransferView extends Backbone.View
  el: '#content'

  events:
    "click #cancel_button": "cancel"
    "click #transfer_button": "transfer"
    "change select#users": "userSelected"

  cancel: ->
    Coconut.router.navigate("##{Coconut.databaseName}", true)

  userSelected: ->
    if $('select').find(":selected").text()
      $('button#transfer_button').prop('disabled', false)
    else
      $('button#transfer_button').prop('disabled', true)

  transfer: =>
    Coconut.checkForInternet
      error: -> alert "Can't connect to internet, transfers require a connection"
      success: =>
        user = $('select').find(":selected").text()
        # See SyncPlugins. These results will be deleted from Cloud when the person receiving the transfer accepts them
        updatedCaseResults = _(@caseResults).map (caseResult) ->
    #      Coconut.debug "Marking #{caseResult._id} as transferred"
          (caseResult.transferred ?= []).push
            from: Coconut.currentUser.get("_id")
            to: $('select').find(":selected").attr "id"
            time: moment().format("YYYY-MM-DD HH:mm")
            notifiedViaSms: []
            received: false
          console.log caseResult
          caseResult

        Coconut.database.bulkDocs updatedCaseResults
        .catch (error) ->
          console.error "Could not save #{JSON.stringify updatedCaseResults}:"
          console.error error
        .then () =>

          Coconut.database.replicate.to Coconut.cloudDB,
            doc_ids: _(@caseResults).pluck "_id"
          .on 'error', (info) =>
            alert "Sync failed, so transfers will be delayed until next sync."
            return
          .on 'complete', (info) =>
              # Delete local version of results See testRemoveAndReplicateBack.coffee
              # This allows cases to be transferred back (when they will be a new document with same doc id but different rev history)
              # Since we have deleted this doc any new revision of the doc will be allowed

              for caseResult in @caseResults
                await Coconut.database.remove(await Coconut.database.get caseResult._id)
              alert "Case #{@caseID} has been successfully transferred to #{user}"
              Coconut.router.navigate "##{Coconut.databaseName}", trigger: true
        .catch (error) ->
          alert error

  render: =>
    @$el.html "
      <style>
        th.header { text-align: left;}
        .mdl-select { width: inherit;}
        table.dataTable tbody td { padding: 8px 20px;}
        table.dataTable thead .sorting, table.dataTable thead .sorting_asc, table.dataTable thead .sorting_desc,
        table.dataTable thead .sorting_asc_disabled, table.dataTable thead .sorting_desc_disabled {
          background-position: center left; }
      </style>
      <div style='padding-bottom: 20px;'>
        <h3 class='content_title'>Transfer this case to:</h3>
        <div class='mdl-select mdl-js-select mdl-select--floating-label'>
          <select class='mdl-select__input users' id='users' name='users'>
            <option></option>
          </select>
          <label class='mdl-select__label' for=users'>Select User</label>
        </div>
        <div>
         <button class='mdl-button mdl-js-button mdl-button--raised mdl-js-ripple-effect' id='cancel_button'>Cancel</button> &nbsp;
         <button class='mdl-button mdl-js-button mdl-button--raised mdl-js-ripple-effect mdl-button--colored' id='transfer_button' disabled>Transfer</button>
        </div>
      </div>
      <h4>Case Results to be transferred:</h4>
      <div>
        <table id='summary' class='tablesorter hover'>
          <thead><tr>
            <th class='header'>Case ID</th>
            <th class='header'>Question</th>
            <th class='header'>Complete</th>
          </tr></thead>
          <tbody>

          </tbody>
        </table>
      </div>
    "

    Coconut.database.query "usersByDistrict",
      include_docs: true
    .then (result) ->
      $("#content select").append(_(result.rows).map (user) ->
        return "" unless user.key? or user.doc.inactive
        return "" if user.key is ""
        "<option id='#{user.id}'>#{user.key} - #{user.value.join(' -  ')}</option>"
      .join ""
      )

    Coconut.database.query "cases",
      key: @caseID
      include_docs: true
    .catch (error) =>
      console.error error if error
    .then (result) =>
      @caseResults = _.pluck(result.rows, "doc")
      $("table#summary tbody").append(_(@caseResults).map (caseResult) ->
        completed = if caseResult.complete == true then 'Yes' else 'No'
        "
          <tr>
            <td>#{caseResult.MalariaCaseID}</td>
            <td>#{caseResult.question}</td>
            <td>#{if caseResult.complete == true then 'Yes' else 'No'}</td>
          </tr>
        "
      .join "")

module.exports = TransferView
