Result::wasTransferredOut = ->
  transferred = @get "transferred"
  if transferred?
    transferredTo = transferred[transferred.length-1].to
    if transferredTo isnt Coconut.currentUser.id
      return true
  return false
