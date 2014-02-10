BaseMessage = require './base_message'

module.exports = class CreateMessage extends BaseMessage
  @type = 'aio:create'

  constructor: (attributes) ->
    @id = attributes.id
    @boxId = +attributes.boxId
    @runtime = attributes.runtime
    @snapshotId = +attributes.snapshotId
    @memory = attributes.memory
    @virtualMemory = attributes.virtualMemory
    @diskSpace = attributes.diskSpace
    @publicKeys = attributes.publicKeys
    @name = attributes.name
    @sshKeyPair = attributes.sshKeyPair
    @cpuShares = +attributes.cpuShares
    @premium = attributes.premium == "true" || attributes.premium == true

    super
