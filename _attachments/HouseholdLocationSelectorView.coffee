class HouseholdLocationSelectorView extends Backbone.View
  constructor: (@targetLocationField) ->
    @prefix = Math.floor(Math.random()*1000)
    @setElement $("
      <div style='padding-left:40px' class='travelLocations'>
        #{@addLocationButton()}
      </div>
    ")
    @targetLocationField.after @el
    _(@targetLocationField.val().split(/,/)).each (location) =>
      return if location is ""
      [locationName, entryPoint] = location.split(/: /)
      locationSelector = @addLocation()
      locationSelector.find("[name=travelLocationName]").val locationName
      locationSelector.find("[value=#{entryPoint}]").prop('checked',true)

  events:
    "change input[name=travelLocationName]": "updateTargetLocationField"
    "change input.radio": "updateTargetLocationField"
    "click button.addLocation": "addLocation"
    "click button.removeLocation": "remove"
 
  addLocationButton: -> "
    <button type='button' class='addLocation mdl-button mdl-js-button mdl-button--raised mdl-js-ripple-effect mdl-button--accent'>
      Add location
    </button>
  "

  remove: (event) =>
    $(event.target).parent().parent().remove()
    console.debug @$('.addLocation').length
    if @$('.addLocation').length is 0
      @$el.append @addLocationButton()
    @updateTargetLocationField()

  addLocation: () =>
    #@$('.addLocation').parent().remove()
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
        <button type='button' class='removeLocation mdl-button mdl-js-button mdl-button--raised mdl-js-ripple-effect mdl-button--accent'>Remove location</button>
        #{@addLocationButton()}
      </div>
    ")
    travelLocations.append travelLocationSelector

    return travelLocationSelector

  updateTargetLocationField: =>
    
    @targetLocationField.val(_.map @$el.find(".travelLocation"), (location) ->
      locationName = $(location).find("input[name='travelLocationName']").val()
      entryMethod = $(location).find("input.entrymethod:checked").val() or ""
      
      "#{locationName}: #{entryMethod}"
    .join(", ")
    ).change() # Needed to trigger change event

module.exports = HouseholdLocationSelectorView
