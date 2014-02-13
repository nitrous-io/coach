BaseMessage = require './base_message'

module.exports = class RestartedMessage extends BaseMessage
  @type = 'aio:restarted'

  constructor: (attributes) ->
    @id = attributes.id
    @boxId = attributes.boxId
    @name = attributes.name
    @data = attributes.data
    super
