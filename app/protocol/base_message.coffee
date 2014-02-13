module.exports = klass = class BaseMessage
  @type: ''

  constructor: (attributes) ->
    @type = this.constructor.type
    @returnVars = attributes.returnVars

  encode: ->
    JSON.stringify(this)
