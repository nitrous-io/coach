BaseMessage = require './base_message'

module.exports = class MigratedMessage extends BaseMessage
  @type = 'aio:migrated'

  constructor: (attributes) ->
    @id = attributes.id
    @boxId = attributes.boxId
    @name = attributes.name
    @success = attributes.success
    super
