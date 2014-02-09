m = require '../protocol'

module.exports = class MessageParser
  @types:
    'aio:locate'          : m.LocateMessage
    'aio:advertise'       : m.AdvertiseMessage
    'aio:create'          : m.CreateMessage
    'aio:created'         : m.CreatedMessage
    'aio:start'           : m.StartMessage
    'aio:started'         : m.StartedMessage
    'aio:stop'            : m.StopMessage
    'aio:stopped'         : m.StoppedMessage
    'aio:restart'         : m.RestartMessage
    'aio:restarted'       : m.RestartedMessage
    'aio:destroy'         : m.DestroyMessage
    'aio:destroyed'       : m.DestroyedMessage
    'aio:snapshot'        : m.SnapshotMessage
    'aio:snapshotted'     : m.SnapshottedMessage
    'aio:delete_snapshot' : m.DeleteSnapshotMessage
    'aio:deleted_snapshot': m.DeletedSnapshotMessage
    'aio:configure'       : m.ConfigureMessage
    'aio:configured'      : m.ConfiguredMessage
    'aio:invalid:params'  : m.InvalidParamsMessage
    'aio:info_request'    : m.InfoRequestMessage
    'aio:info_response'   : m.InfoResponseMessage
    'aio:migrate'         : m.MigrateMessage
    'aio:migrated'        : m.MigratedMessage

  @decode: (messageJSON) ->
    parsedMessage = JSON.parse(messageJSON)
    if parsedMessage.type? && (msgKlass = @types[parsedMessage.type])?
      new msgKlass(parsedMessage)
    else
      null
