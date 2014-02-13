BaseMessage = require './base_message'

module.exports = class MigrateMessage extends BaseMessage
  @type = 'aio:migrate'

  constructor: (attributes) ->
    @id = attributes.id
    @boxId = attributes.boxId
    @name = attributes.name
    super
