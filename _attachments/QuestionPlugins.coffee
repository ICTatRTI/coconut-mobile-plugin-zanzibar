Question::summaryFieldsMappedToResultPropertyNames = ->
  returnVal = {}
  for field in Object.keys(@resultSummaryFields())
    returnVal[field] = capitalize(camelize(field))

  returnVal["Malaria Case ID"] = "MalariaCaseID"

  returnVal

