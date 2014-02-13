BaseMessage = require './base_message'

module.exports = class SnapshotMessage extends BaseMessage
  @type = 'aio:snapshot'

  constructor: (attributes) ->
    @id = attributes.id
    @boxId = attributes.boxId
    @name = attributes.name
    @snapshotId = +attributes.snapshotId
    @data = attributes.data # Reserved for things like a list of files to be excluded.
    super
