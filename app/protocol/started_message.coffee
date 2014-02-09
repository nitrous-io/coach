BaseMessage = require './base_message'

module.exports = class StartedMessage extends BaseMessage
  @type = 'aio:started'

  constructor: (attributes) ->
    @id = attributes.id
    @boxId = attributes.boxId
    @name = attributes.name
    @data = attributes.data
    super
