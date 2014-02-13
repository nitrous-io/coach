BaseMessage = require './base_message'

module.exports = class InvalidParamsMessage extends BaseMessage
  @type = 'aio:invalid:params'

  constructor: (attributes) ->
    @id = attributes.id
    super
