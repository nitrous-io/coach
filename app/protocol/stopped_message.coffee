BaseMessage = require './base_message'

module.exports = class StoppedMessage extends BaseMessage
  @type = 'aio:stopped'

  constructor: (attributes) ->
    @id = attributes.id
    @boxId = attributes.boxId
    super
