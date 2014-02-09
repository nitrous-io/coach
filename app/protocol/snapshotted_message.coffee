BaseMessage = require './base_message'

module.exports = class SnapshottedMessage extends BaseMessage
  @type = 'aio:snapshotted'

  constructor: (attributes) ->
    @id = attributes.id
    @boxId = attributes.boxId
    @name = attributes.name
    @snapshotId = attributes.snapshotId
    super
