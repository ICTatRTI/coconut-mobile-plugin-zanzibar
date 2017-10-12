class SummaryView extends Backbone.View
  el: '#content'

  render: (result) =>
    @$el.html "
      <style>
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

      </style>
      <h4 class='content_title'>Cases on this device:</h4>

      <table id='summary' class='tablesorter hover'>
        <thead><tr>
          <th class='header'>Date</th>
          <th class='header'>ID</th>
          <th class='header'>Type</th>
          <th class='header'>Complete</th>
          <th class='header'>Transfer</th>
          <th class='header'>Options</th>
        </tr></thead>
        <tbody>
        #{
          _.map result.rows, (row) ->
            result = "
              <tr>
                <td>#{row.key}</td>
                <td><a class='button' href='##{Coconut.databaseName}/edit/result/#{row.id}'>#{row.value[0]}</a></td>
                <td>#{row.value[1]}</td>
                <td>#{if row.value[2] then 'Yes' else 'No'}</td>
                <td><small>
                  <pre>
                  #{
                    if row.value[3]? then JSON.stringify(row.value[3],null,2).replace(/({\n|\n}|\")/g,"") else ""
                  }
                  </pre></small></td>
                <td> <a class='button mdi mdi-transfer mdi-24px' style='text-decoration:none' href='##{Coconut.databaseName}/transfer/#{row.value[0]}' title='Transfer'></a></td>
              </tr>
            "
          .join ""
        }
        </tbody>
      </table>

    "
    $("table#summary").DataTable
      retrieve: true
      aaSorting: [[0,"desc"]]
      scrollX: true
      lengthMenu: [ [10, 25, 50, 100, -1], [10, 25, 50, 100, "All"] ]
      dom: '<lf<t>ip>'
      iDisplayLength: 25
      drawCallback: () ->
        $(".dataTables_scrollHeadInner").css("width":"100%")
        $(".dataTable.no-footer").css("width":"100%")

module.exports = SummaryView
