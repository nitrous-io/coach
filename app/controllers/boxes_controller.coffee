protocol              = require '../protocol'
settings              = require '../../config/settings'
ApplicationController = require './application_controller'
initRedisClientWith   = require('../lib/utils').initRedisClientWith
publisher             = initRedisClientWith(settings.redisMQ)
log                   = require('../lib/log')

module.exports = class BoxesController extends ApplicationController
  create: ->
    boxerListener = require('../../app').boxerListener

    boxer = boxerListener.chooseBoxer
      runtime: @params.box.runtime
      snapshotId: @params.box.snapshot_id

    attributes =
                name: @params.box.name
                boxId: @params.box.id
                runtime: @params.box.runtime
                memory: @params.box.memory
                diskSpace: @params.box.disk_space
                virtualMemory: @params.box.virtual_memory
                cpuShares: @params.box.cpu_shares
                snapshotId: @params.box.snapshot_id
                snapshotUrl: @params.box.snapshot_url
                premium: @params.box.premium

    if @params.box.public_keys?
      try
        attributes.publicKeys = JSON.parse(@params.box.public_keys)
      catch error
        log "Error in Parsing Public Keys: #{error}"

    if boxer?
      attributes['id'] = boxer.id
      log "Box ID: #{attributes.boxId}"
      this._renderResult(protocol.CreateMessage, attributes)
    else
      @response.send 404, JSON.stringify("status":"MISSING")

  show: ->
    attributes =
                name: @params.name
                id: @params.box.boxer_id

    this._renderResult(protocol.InfoRequestMessage, this._mergeReturnVars(attributes))

  start: ->
    attributes =
                name: @params.name
                id: @params.box.boxer_id
                publicKeys: @params.box.public_keys
    try
      attributes.data = JSON.parse @params.box.data
    catch error
      log "Error in Parsing Configuration Data: #{error}"

    this._renderResult(protocol.StartMessage, this._mergeReturnVars(attributes))

  stop: ->
    attributes =
                name: @params.name
                id: @params.box.boxer_id
    this._renderResult(protocol.StopMessage, this._mergeReturnVars(attributes))

  restart: ->
    attributes =
                name: @params.name
                id: @params.box.boxer_id
    try
      attributes.data = JSON.parse @params.box.data
    catch error
      log "Error in Parsing Configuration Data: #{error}"

    this._renderResult(protocol.RestartMessage, this._mergeReturnVars(attributes))

  destroy: ->
    attributes =
                name: @params.name
                id: @params.box.boxer_id
    this._renderResult(protocol.DestroyMessage, this._mergeReturnVars(attributes))

  update: ->
    attributes =
                name: @params.name
                id: @params.box.boxer_id
                dataType: @params.box.data_type

    switch attributes.dataType
      when 'aio:configure:remove_env_variables'
      , 'aio:configure:set_env_variables'
      , 'aio:configure:change_specs'
      , 'aio:configure:update_auth'
      , 'aio:configure:update_premium'
      , 'aio:configure:update_custom_domain'
        try
          attributes.data = JSON.parse @params.box.data
        catch error
          log "Error in Parsing Configuration Data: #{error}"
      else
        attributes.data = @params.box.data

    this._renderResult(protocol.ConfigureMessage, this._mergeReturnVars(attributes))

  snapshot: ->
    attributes =
                name: @params.name
                id: @params.box.boxer_id
                snapshotId: @params.box.snapshot_id
    this._renderResult(protocol.SnapshotMessage, this._mergeReturnVars(attributes))

  deleteSnapshot: ->
    attributes =
                snapshotId: @params.snapshotId
                id: @params.box.boxer_id
                snapshotUrl: @params.snapshot_url
    this._renderResult(protocol.DeleteSnapshotMessage, this._mergeReturnVars(attributes))

  migrate: ->
    attributes =
                name: @params.name
                id: @params.box.boxer_id
                boxId: @params.box.id
    this._renderResult(protocol.MigrateMessage, attributes)

  _renderResult: (klass, attributes) ->
    message = new klass(attributes)

    self = this
    publisher.publish settings.boxerChannel, message.encode(), (err, res) ->
      if !err
        self.response.send 202, JSON.stringify
                                          "status" : "OK"
      else
        self.response.send 500, JSON.stringify
                                          "status" : "ERROR"
                                          "text" : err

  _mergeReturnVars: (attributes) ->
    if @params.return_vars?
      try
        parsedReturnVars = JSON.parse(@params.return_vars)
        attributes.returnVars = parsedReturnVars
      catch error
        log "Error in parsing return vars: #{error}"

    attributes
