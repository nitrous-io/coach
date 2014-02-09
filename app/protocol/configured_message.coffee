BaseMessage = require './base_message'

module.exports = class ConfiguredMessage extends BaseMessage
  @type = 'aio:configured'

  constructor: (attributes) ->
    @id = attributes.id
    @name = attributes.name
    @boxId = attributes.boxId
    @success = attributes.success
    @data = attributes.data
    @dataType = attributes.dataType
    super
