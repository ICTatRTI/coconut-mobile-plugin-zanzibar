class HouseholdLocationSelectorView extends Backbone.View
  constructor: (@targetLocationField, disableTarget = true) ->
    @prefix = Math.floor(Math.random()*1000)
    @setElement $("
      <div style='padding-left:40px' class='travelLocations'>
      </div>
    ")
    @targetLocationField.after @el
    _(@targetLocationField.val().split(/,/)).each (location) =>
      return if location.replace(/ *:* */,"") is ""
      [locationName, entryPoint] = location.split(/: /)
      locationSelector = @addLocation()
      locationSelector.find("[name=travelLocationName]").val locationName
      locationSelector.find("[value='#{entryPoint}']").prop('checked',true)
    @$el.append @addLocationButton() if @$('.addLocation').length is 0
    @targetLocationField.prop('disabled', disableTarget)

  events:
    "change input[name=travelLocationName]": "updateTargetLocationField"
    "change input.radio": "updateTargetLocationField"
    "click button.addLocation": "addLocation"
    "click button.removeLocation": "remove"
 
  addLocationButton: -> "
    <button type='button' style='position:static' class='addLocation mdl-button mdl-js-button mdl-button--raised mdl-js-ripple-effect mdl-button--accent'>
      Add location
    </button>
  "

  removeLocationButton: -> "
    <button type='button' style='margin-top:10px;margin-bottom:10px;display:block;position:static' class='removeLocation mdl-button mdl-js-button mdl-button--raised mdl-js-ripple-effect mdl-button--accent'>Remove location</button>
  "

  remove: (event) =>
    $(event.target).closest(".travelLocation").remove()
    if @$('.addLocation').length is 0
      @$el.append @addLocationButton() if @$('.addLocation').length is 0
    @updateTargetLocationField()

  addLocation: (event) =>
    $(event.target).closest("button.addLocation").remove() if event # Remove the addLocation button that was clicked
    @prefix+=1
    
    travelLocations = @targetLocationField.siblings(".travelLocations")

    travelLocationSelector = $("
      <div class='travelLocation' id='#{@prefix}'>
        <label class='mdl-textfield__label' type='text' for='travelLocationName'>Location Name</label>
        <input class='mdl-textfield__input' name='travelLocationName' type='text'/>

        <label class='mdl-textfield__label' type='text' for='entry'>Entry Point</label>
          #{
            _(["Ferry","Informal Ferry","Airport"]).map (entryMethod, index) =>
              "
              <input class='radio entrymethod' type='radio' name='#{@prefix}-entry' id='#{@prefix}-#{index}' value='#{entryMethod}'/>
              <label class='mdl-nontextfield__label radio radio-option' for='#{@prefix}-#{index}'>#{entryMethod}</label>
              "
            .join("")
          }
        #{@removeLocationButton()}
      </div>
    ")
    travelLocations.append travelLocationSelector

    return travelLocationSelector

  updateTargetLocationField: =>
    @targetLocationField.val(
      val = _.chain(@$el.find(".travelLocation")).map (location) =>
        locationName = $(location).find("input[name='travelLocationName']").val()
        entryMethod = $(location).find("input.entrymethod:checked").val() or ""
        if locationName
          if @$el.find("button.addLocation").length is 0
            @$el.append @addLocationButton()
          "#{locationName}: #{entryMethod}"
        else
          null
      .compact().join(", ").value()
    ).change() # Needed to trigger change event
    @targetLocationField.closest("div.mdl-textfield").addClass "is-dirty"

module.exports = HouseholdLocationSelectorView
