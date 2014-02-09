BaseMessage = require './base_message'

module.exports = class InfoResponseMessage extends BaseMessage
  @type = 'aio:info_response'

  constructor: (attributes) ->
    @id = attributes.id
    @boxId = attributes.boxId
    @name = attributes.name
    @info = attributes.info
    @success = attributes.success
    super

