publisher = require '../lib/redis_client'
protocol = require '../protocol'
settings = require '../../config/settings'

ApplicationController = require './application_controller'

module.exports = class BoxesController extends ApplicationController
  create: ->
    attributes =
                name: @params['box'].name
                boxId: @params['box'].id
                runtime: @params['box'].runtime
                memory: @params['box'].memory
                diskSpace: @params['box'].disk_space
                snapshotURL: @params['box'].snapshot_url
                # TODO: add the boxer ID we want to send to

    this._renderResult(protocol.CreateMessage, attributes)

  start: ->
    attributes =
                name: @params['name']
                id: @params['box'].boxer_id
    this._renderResult(protocol.StartMessage, attributes)

  stop: ->
    attributes =
                name: @params['name']
                id: @params['box'].boxer_id
    this._renderResult(protocol.StopMessage, attributes)

  destroy: ->
    attributes =
                name: @params['name']
                id: @params['box'].boxer_id
    this._renderResult(protocol.DestroyMessage, attributes)

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

