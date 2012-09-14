MessageParser = require './message_parser'
ActionWebhook = require './action_webhook'
protocol = require '../protocol'
initRedisClientWith = require('./utils').initRedisClientWith
_ = require 'underscore'

class Boxer
  @EXPIRY_TIME = 10

  constructor: (@id, @runtimes, @freeMemory) ->
    @lastUpdatedAt = new Date().valueOf()


module.exports = class BoxerListener
  constructor: (@settings) ->
    @listener = initRedisClientWith(@settings.redisMQ)
    @boxers = {}

  run: ->
    self = this

    @listener.subscribe @settings.coachChannel, (err, result) ->
      if !err
        self.listener.on 'message', (channel, rawMessage) ->
          parsedMessage = MessageParser.decode(rawMessage)
          self._handle(parsedMessage)

  _handle: (message) ->
    if message.type == protocol.AdvertiseMessage.type
      # add the boxer to the list of boxers who report to the coach
      if (boxer = @boxers[message.id])?
        boxer.lastUpdatedAt = new Date().valueOf()
      else
        @boxers[message.id] = new Boxer(message.id, message.runtimes, message.freeMemory)
    else if message.type == protocol.StartedMessage.type ||
            message.type == protocol.StoppedMessage.type ||
            message.type == protocol.DestroyedMessage.type
      # Send a notification to Pusher
      # Call the web hook in action.io which updates the status of the box
      boxId = message.boxId
      ActionWebhook.sendNotification message, (err) ->
        if err
          console.log "Error -> #{err} while sending notification"

  chooseBoxer: (runtime, memory) ->
    # Randomize the available boxer (if there is more than one available)
    availableBoxerIds = _.shuffle(_.keys(@boxers))
    self = this
    availableBoxer = null

    _.each availableBoxerIds, (id) ->
      boxer = self.boxers[id]

      if new Date().valueOf() - boxer.lastUpdatedAt >= Boxer.EXPIRY_TIME
        self.boxers[id] = null
      else if (parseInt(boxer.freeMemory) > parseInt(memory) &&
               _.include(boxer.runtimes, runtime))
        availableBoxer = boxer

    availableBoxer

