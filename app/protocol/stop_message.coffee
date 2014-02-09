BaseMessage = require './base_message'

module.exports = class StopMessage extends BaseMessage
  @type = 'aio:stop'

  constructor: (attributes) ->
    @id = attributes.id
    @boxId = attributes.boxId
    @name = attributes.name
    super
