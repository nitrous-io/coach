protocol              = require '../protocol'
settings              = require '../../config/settings'
ApplicationController = require './application_controller'
initRedisClientWith   = require('../lib/utils').initRedisClientWith
publisher             = initRedisClientWith(settings.redisMQ)

module.exports = class BoxesController extends ApplicationController
  create: ->
    boxerListener = require('../../app').boxerListener

    boxer = boxerListener.chooseBoxer @params.box.runtime,
                                      @params.box.memory,
                                      @params.box.disk_space

    attributes =
                name: @params.box.name
                boxId: @params.box.id
                runtime: @params.box.runtime
                memory: @params.box.memory
                diskSpace: @params.box.disk_space
                snapshotURL: @params.box.snapshot_url

    if @params.box.public_keys?
      try
        attributes.publicKeys = JSON.parse(@params.box.public_keys)
      catch error
        console.log "Error in Parsing Public Keys: #{error}"

    if boxer?
      attributes['id'] = boxer.id
      console.log "Box ID: #{attributes.boxId}"
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
      when 'aio:configure:remove_env_variables', 'aio:configure:set_env_variables', 'aio:configure:change_specs'
        try
          attributes.data = JSON.parse @params.box.data
        catch error
          console.log "Error in Parsing Configuration Data: #{error}"
      else
        attributes.data = @params.box.data

    this._renderResult(protocol.ConfigureMessage, this._mergeReturnVars(attributes))

  snapshot: ->
    attributes =
      name: @params.name
      id: @params.box.boxer_id
    this._renderResult protocol.SnapshotMessage, this._mergeReturnVars(attributes)

  migrate: ->
    if @params.box.excluded_hosts?
      try
        # make sure that this is an array
        excludedHosts = [].concat JSON.parse(@params.box.excluded_hosts)
      catch error
        @response.send 404, JSON.stringify("status":"MISSING")
    else
      @response.send 404, JSON.stringify("status":"MISSING")

    attributes =
                id: @params.box.boxer_id
                name: @params.box.name
                boxId: @params.box.id
                runtime: @params.box.runtime
                memory: @params.box.memory
                diskSpace: @params.box.disk_space
                snapshotURL: @params.box.snapshot_url
                excludedHosts: excludedHosts
                dataType: "aio:migrate:snapshot"

    if @params.box.public_keys?
      try
        attributes.publicKeys = JSON.parse(@params.box.public_keys)
      catch error
        console.log "Error in Parsing Public Keys: #{error}"

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
        console.log "Error in parsing return vars: #{error}"

    attributes
