publisher = require '../lib/redis_client'
protocol = require '../protocol'
settings = require '../../config/settings'
logger = require '../lib/logger'
ApplicationController = require './application_controller'

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
        logger.error "Error in Parsing Public Keys: #{error}"

    if @params.box.ssh_key_pair?
      try
        attributes.sshKeyPair = JSON.parse @params.box.ssh_key_pair
      catch error
        logger.error "Error in Parsing SSH Key Pair: #{error}"

    if boxer?
      attributes['id'] = boxer.id
      console.log "Box ID: #{attributes.boxId}"
      this._renderResult(protocol.CreateMessage, attributes)
    else
      @response.send 404, JSON.stringify("status":"MISSING")


  start: ->
    attributes =
                name: @params.name
                id: @params.box.boxer_id
    this._renderResult(protocol.StartMessage, attributes)

  stop: ->
    attributes =
                name: @params.name
                id: @params.box.boxer_id
    this._renderResult(protocol.StopMessage, attributes)

  destroy: ->
    attributes =
                name: @params.name
                id: @params.box.boxer_id
    this._renderResult(protocol.DestroyMessage, attributes)

  update: ->
    attributes =
                name: @params.name
                id: @params.box.boxer_id
                dataType: @params.box.data_type
                data: @params.box.data

    this._renderResult(protocol.ConfigureMessage, attributes)

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

