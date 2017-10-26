global.dasherize = require("underscore.string/dasherize")
global.camelize = require("underscore.string/camelize")
global.capitalize = require("underscore.string/capitalize")

# This is needed because old Coconut used camelcase instead of slugify. Camelcase created bad ids sometimes

originalJs2form = Form2js.js2form
Form2js.js2form = ->
  #console.log arguments[1]

  transformedResult = {}
  _(arguments[1]).each (value, property) ->
    if _([
      "lastModifiedAt"
      "createdAt"
      "savedBy"
    ]).contains(property) or property[0] is "_"
      transformedResult[property] = value
    else
      property = slugify(dasherize(property))
      property = property.replace(/i-d$/, "id")
      transformedResult[property] = value

  arguments[1] = transformedResult

  originalJs2form.apply(this,arguments)


originalForm2js = Form2js.form2js
Form2js.form2js = ->
  result = originalForm2js.apply(this,arguments)
  #console.log result
  transformedResult = {}
  _(result).each (value, property) ->
    property = capitalize(camelize(property))
    property = property.replace(/Id$/, "ID")
    transformedResult[property] = value
  return transformedResult

