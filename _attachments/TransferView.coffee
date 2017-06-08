Dialog = require './js-libraries/modal-dialog'

class TransferView extends Backbone.View
  el: '#content'
  initialize: (options) =>
    @options = options
    _.bindAll(this, 'render')

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
    user = $('select').find(":selected").text()
    caseID = @options.caseID
    caseResults = @options.caseResults
    _(caseResults).each (caseResult) ->
#      Coconut.debug "Marking #{caseResult._id} as transferred"
      caseResult.transferred = [] unless caseResult.transferred?
      caseResult.transferred.push {
        from: Coconut.currentUser.get("_id")
        to: $('select').find(":selected").attr "id"
        time: moment().format("YYYY-MM-DD HH:mm")
        notifiedViaSms: []
        received: false
      }
    Coconut.cloudDatabase.bulkDocs {docs: caseResults}
    .catch (error) ->
      console.error "Could not save #{JSON.stringify caseResults}:"
      console.error error
    .then () ->
      Dialog.showDialog
        title: "CASE TRANSFER",
        text: "Case #{caseID} has been successfully transferred to #{user}"
        neutral:
          title: "Continue"
          onClick: (e) ->
            dialog = $('#orrsDiag')
            Dialog.hideDialog dialog, () ->
              Coconut.router.navigate("##{Coconut.databaseName}", true)

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
          <select class='mdl-select__input' id='users' name='users'>
            <option></option>
          </select>
          <label class='mdl-select__label' for=users'>User</label>
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

    Coconut.database.query "usersByDistrict", {},
      (error,result) ->
        $("#content select").append(_(result.rows).map (user) ->
          return "" unless user.key?
          "<option id='#{user.id}'>#{user.key}   #{user.value.join('   ')}</option>"
        .join ""
        )

    Coconut.database.query "cases",
      key: @options.caseID
      include_docs: true
    ,
      (error, result) =>
        console.error error if error

        caseResults = _.pluck(result.rows, "doc")
        @options.caseResults = caseResults
        $("table#summary tbody").append(_(caseResults).map (caseResult) ->
          completed = if caseResult.complete == true then 'Yes' else 'No'
          "
            <tr>
              <td>#{caseResult.MalariaCaseID}</td>
              <td>#{caseResult.question}</td>
              <td>#{if caseResult.complete == true then 'Yes' else 'No'}</td>
            </tr>
          "
        .join "")

        $("table#summary").DataTable
          aaSorting: [[0,"desc"]]
          scrollX: true
          searching: false
          paging: false
          info: false
          drawCallback: () ->
            $(".dataTables_scrollHeadInner").css("width":"100%")
            $(".dataTable.no-footer").css("width":"100%")

module.exports = TransferView
