BaseMessage = require './base_message'

module.exports = class DestroyedMessage extends BaseMessage
  @type = 'aio:destroyed'

  constructor: (attributes) ->
    @id = attributes.id
    @boxId = attributes.boxId
    @snapshotId = attributes.snapshotId
    @snapshotUrl = attributes.snapshotUrl
    @snapshotSize = attributes.snapshotSize
    @success = attributes.success
    super
