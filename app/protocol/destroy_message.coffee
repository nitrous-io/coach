BaseMessage = require './base_message'

module.exports = class DestroyMessage extends BaseMessage
  @type = 'aio:destroy'

  constructor: (attributes) ->
    @id = attributes.id
    @boxId = attributes.boxId
    @name = attributes.name
    super
