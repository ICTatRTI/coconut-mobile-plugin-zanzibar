# db:keep
(doc) ->
  emit(doc._id, null) if doc.collection is "user" or doc.collection is "question"
  emit(doc._id, null) if doc.isApplicationDoc is true
