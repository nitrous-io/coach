BaseMessage = require './base_message'

module.exports = class InfoRequestMessage extends BaseMessage
  @type = 'aio:info_request'

  constructor: (attributes) ->
    @id = attributes.id
    @boxId = attributes.boxId
    @name = attributes.name
    super

