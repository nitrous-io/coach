MessageParser = require './message_parser'
initRedisClientWith = require('./utils').initRedisClientWith
_ = require 'underscore'

module.exports = class BoxerListener
  constructor:(@settings) ->
    @listener = initRedisClientWith(@settings.redisMQ)

  run: ->
    self = this

    @listener.subscribe @settings.boxerChannel, (err, result) ->
      if !err
        self.listener.on 'message', (channel, rawMessage) ->
          parsedMessage = MessageParser.decode(rawMessage)
          self._handle(parsedMessage)

  _handle: (message) ->


  chooseBoxer: (runtime, memory, diskSpace) ->
    null

