class SummaryView extends Backbone.View
  el: '#content'

  render: (@cases) =>
    @$el.html "
      <style>#{@css()}</style>

      <h4 class='content_title'>Facility Cases For Past Month on Tablet:</h4>
      (note that only cases with a complete facility visit may be transferred)<br/>

      <div id='facility-cases-table'></div>

      <h4 class='content_title'>Positive Individuals From Facility Cases:</h4>
      (includes all people that test positive including at the household)<br/>
      <div id='positive-individuals-table'></div>
    "


    @facilityCasesTabulator()
    @positiveIndividualsTabulator()

  facilityCasesTabulator: =>
    columns = for columnName in [
     "Diagnosis Date"
      "Time Facility Notified"
      "Time Followup Complete"
      "Hours From Notification Until Complete"
      "ID"
      "Facility"
      "Status"
      "Options"
    ]
      column = { title: columnName, field: columnName}
      if columnName is "Status" or columnName is "Options"
        column["formatter"] = "html"
      if columnName.match(/ /)
        column["width"] = 120
      column


    data = for facilityCase in @cases
      result = {
        "Diagnosis Date": facilityCase.indexCaseDiagnosisDate()
        "Time Facility Notified": facilityCase.timeFacilityNotified()?[0..-4] or "-"
        "Time Followup Complete": facilityCase.timeOfHouseholdComplete()?[0..-4] or "-"
        "Hours From Notification Until Complete": facilityCase.hoursFromNotificationToCompleteHousehold() or "-"
        "ID": facilityCase.caseID
        "Facility": facilityCase.facility()
        "Status": ""
        "Options": ""
      }
      lastTransferEntry = _(facilityCase["Facility"]?.transferred).last()
      if lastTransferEntry?.from is Coconut.currentUser.id
        transferredTo = Coconut.users.findWhere(_id:lastTransferEntry.to).get("name")
        result["Status"] = "Transferred to #{transferredTo} (#{lastTransferEntry.to.replace(/user./,"")})"
      else
        result["Status"] = facilityCase.status()
        if facilityCase.hasCompleteFacility() and not facilityCase.complete()
          result["Options"] = "<a style='text-decoration:none' href='##{Coconut.databaseName}/transfer/#{facilityCase.caseID}' title='Transfer'>Transfer</a>"

      result

    @tabulator = new Tabulator "#facility-cases-table",
      maxHeight: "50%"
      layout: "fitColumns"
      data: data
      columns: columns
      ###
      rowClick: (e,row) =>
        Coconut.router.navigate("#{Coconut.databaseName}/edit/result/#{row.getData()._id}", {trigger:true})
      ###

  positiveIndividualsTabulator: =>
    columns = for columnName in [
      "Diagnosis Time"
      "Facility Case ID"
      "Classification"
      "Focal Shehia"
      "Evidence"
    ]
      column = { title: columnName, field: columnName}
      if columnName is "Facility Case ID"
        column["width"] = 100
      if columnName is "Evidence"
        column["formatter"] = "textarea"
      column

    data = []
    for facilityCase in @cases
      for positiveIndividual in facilityCase.positiveIndividualObjects()
        data.push
          "Diagnosis Time": positiveIndividual.dateOfPositiveResults().replace(/T/," ")
          "Facility Case ID": positiveIndividual.data.MalariaCaseID
          "Classification": positiveIndividual.classification()
          "Focal Shehia": positiveIndividual.focalShehia()

    @tabulator = new Tabulator "#positive-individuals-table",
      maxHeight: "50%"
      layout: "fitColumns"
      data: data
      columns: columns
      ###
      rowClick: (e,row) =>
        Coconut.router.navigate("#{Coconut.databaseName}/edit/result/#{row.getData()._id}", {trigger:true})
      ###

  css: => "

    .tabulator .tabulator-header .tabulator-col .tabulator-col-content .tabulator-col-title{
      white-space: normal;
      text-overflow: clip;
    }

    .tabulator-row .tabulator-cell a {
      white-space: pre-wrap;
    }



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
