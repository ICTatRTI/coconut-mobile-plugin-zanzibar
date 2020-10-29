class SummaryView extends Backbone.View
  el: '#content'

  render: (cases) =>
    @$el.html "
      <style>#{@css()}</style>

      <h4 class='content_title'>Facility Cases For Past Month on Tablet:</h4>
      (note that only cases with a complete facility visit may be transferred)<br/>
      <table id='summary' class='tablesorter hover'>
        <thead><tr>
          <th class='header'>Diagnosis Date</th>
          <th class='header'>Time Facility Notified</th>
          <th class='header'>Time Followup Complete</th>
          <th class='header'>Hours From Notification Until Complete</th>
          <th class='header'>ID</th>
          <th class='header'>Facility</th>
          <th class='header'>Status</th>
          <th class='header'>Options</th>
        </tr></thead>
        <tbody>
        #{
          _.map cases, (facilityCase) ->
            result = "
              <tr>
                <td>#{facilityCase.indexCaseDiagnosisDate()}</td>
                <td>#{facilityCase.timeFacilityNotified()?[0..-4] or "-"}</td>
                <td>#{facilityCase.timeOfHouseholdComplete()?[0..-4] or "-"}</td>
                <td>#{facilityCase.hoursFromNotificationToCompleteHousehold() or "-"}</td>
                <td>#{facilityCase.caseID}</td>
                <td>#{facilityCase.facility()}</td>

                #{
                  lastTransferEntry = _(facilityCase["Facility"]?.transferred).last()
                  if lastTransferEntry?.from is Coconut.currentUser.id
                    transferredTo = Coconut.users.findWhere(_id:lastTransferEntry.to).get("name")
                    "
                      <td>Transferred to #{transferredTo} (#{lastTransferEntry.to.replace(/user./,"")})</td>
                      <td></td>
                    "
                  else
                    "
                      <td>#{facilityCase.status()}</td>
                      <td> 
                        #{
                          if facilityCase.hasCompleteFacility() and not facilityCase.complete()
                            "<a style='text-decoration:none' href='##{Coconut.databaseName}/transfer/#{facilityCase.caseID}' title='Transfer'>Transfer</a>"
                          else
                            ""
                        

                        }
                      </td>
                    "
                }
              </tr>
            "
          .join ""
        }
        </tbody>
      </table>

      <h4 class='content_title'>Positive Individuals From Facility Cases:</h4>
      <table id='positiveIndividualsTable' class='tablesorter hover'>
        <thead><tr>
          <th class='header'>Diagnosis Date</th>
          <th class='header'>Facility Case ID</th>
          <th class='header'>Classification</th>
          <th class='header'>Focal Shehia</th>
          <th class='header'>Evidence</th>
        </tr></thead>
        <tbody>
        #{
          _.map cases, (facilityCase) ->
            _(facilityCase.positiveIndividualObjects()).map (positiveIndividual) =>
              result = "
                <tr>
                  <td>#{positiveIndividual.dateOfPositiveResults()}</td>
                  <td>#{positiveIndividual.data.MalariaCaseID}</td>
                  <td>#{positiveIndividual.classification()}</td>
                  <td>#{positiveIndividual.focalShehia()}</td>
                  <td>#{positiveIndividual.data.SummarizeEvidenceUsedForClassification}</td>
                </tr>
              "
            .join ""
          .join ""
        }
        </tbody>
      </table>

    "
    @$("table#summary").DataTable
      retrieve: true
      aaSorting: [[0,"desc"]]
      scrollX: true
      lengthMenu: [ [10, 25, 50, 100, -1], [10, 25, 50, 100, "All"] ]
      dom: '<lf<t>ip>'
      iDisplayLength: 25
      drawCallback: () ->
        @$(".dataTables_scrollHeadInner").css("width":"100%")
        @$(".dataTable.no-footer").css("width":"100%")


  css: => "
    th.header {
      text-align: left;
    }

    table, table.dataTable {
      width: 100%;
      margin: 0;
    }

    .dataTables_filter input{
      display:inline;
      width:300px;
    }

    a[role=button]{
      background-color: white;
      margin-right:5px;
      -moz-border-radius: 1em;
      -webkit-border-radius: 1em;
      border: solid gray 1px;
      font-family: Helvetica,Arial,sans-serif;
      font-weight: bold;
      color: #222;
      text-shadow: 0 1px 0 #fff;
      -webkit-background-clip: padding-box;
      -moz-background-clip: padding;
      background-clip: padding-box;
      padding: .6em 20px;
      text-overflow: ellipsis;
      overflow: hidden;
      white-space: nowrap;
      position: relative;
      zoom: 1;
    }

    a[role=button].paginate_disabled_previous, a[role=button].paginate_disabled_next{
      color:gray;
    }

    a.ui-btn{
      display: inline-block;
      width: 300px;

    }

    .dataTables_info{
      float:right;
    }

    .dataTables_paginate{
      margin-bottom:20px;
    }

    table.dataTable thead .sorting, table.dataTable thead .sorting_asc, table.dataTable thead .sorting_desc, table.dataTable thead .sorting_asc_disabled, table.dataTable thead .sorting_desc_disabled {
      background-position: center left;
    }


  "


module.exports = SummaryView
