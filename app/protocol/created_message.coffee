BaseMessage = require './base_message'

module.exports = class CreatedMessage extends BaseMessage
  @type = 'aio:created'

  constructor: (attributes) ->
    @id = attributes.id
    @boxId = attributes.boxId
    @port = attributes.port
    @success = attributes.success

    super
