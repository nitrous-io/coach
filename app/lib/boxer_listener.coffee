MessageParser       = require './message_parser'
ActionWebhook       = require './action_webhook'
protocol            = require '../protocol'
initRedisClientWith = require('./utils').initRedisClientWith
_                   = require 'underscore'
log                 = require './log'

class Boxer
  @EXPIRY_TIME = 10 * 1000 # 10 seconds

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
      now = new Date().valueOf()

      # add the boxer to the list of boxers who report to the coach
      if (boxer = @boxers[message.id])?
        boxer.lastUpdatedAt = now
        boxer.runtimes = message.runtimes
      else
        @boxers[message.id] = new Boxer(message.id, message.runtimes, message.freeMemory)
        log "Received a boxer update: #{message.id}, number of boxers in my purview: #{_.keys(@boxers).length}"
    else if message.type == protocol.CreatedMessage.type ||
            message.type == protocol.StartedMessage.type ||
            message.type == protocol.StoppedMessage.type ||
            message.type == protocol.RestartedMessage.type ||
            message.type == protocol.DestroyedMessage.type ||
            message.type == protocol.ConfiguredMessage.type ||
            message.type == protocol.SnapshottedMessage.type ||
            message.type == protocol.MigratedMessage.type ||
            message.type == protocol.InfoResponseMessage.type
      log "Received Message Type: #{message.type}"
      # Send a notification to Pusher
      # Call the web hook in action.io which updates the status of the box
      boxId = message.boxId
      ActionWebhook.sendNotification message, (err) ->
        if err
          log "Error -> #{err} while sending notification"

  # Choose a Boxer based on the given requirements.
  chooseBoxer: (requirements) ->
    # Randomize the available boxer (if there is more than one available)
    availableBoxerIds = _.shuffle(_.keys(@boxers))
    availableBoxer = null

    memory = requirements.memory
    runtime = requirements.runtime

    log "Available Boxer IDs: #{availableBoxerIds}"

    _.each availableBoxerIds, (id) =>
      boxer = @boxers[id]
      log "Value Of Updated At --> #{new Date().valueOf() - boxer.lastUpdatedAt}"

      if new Date().valueOf() - boxer.lastUpdatedAt >= Boxer.EXPIRY_TIME
        log "Error: Expired Boxer: #{id}, deleting"
        @boxers[id] = null
      else
        if parseInt(boxer.freeMemory) > parseInt(memory)
          if _.include(boxer.runtimes, runtime)
            availableBoxer = boxer

    availableBoxer
