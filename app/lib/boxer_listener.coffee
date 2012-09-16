MessageParser = require './message_parser'
ActionWebhook = require './action_webhook'
protocol = require '../protocol'
logger = require './logger'
initRedisClientWith = require('./utils').initRedisClientWith
_ = require 'underscore'

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
    logger.info "Received Message Type: #{message.type}"

    if message.type == protocol.AdvertiseMessage.type
      # add the boxer to the list of boxers who report to the coach
      if (boxer = @boxers[message.id])?
        updatedAt = new Date().valueOf()
        logger.debug "Updating #{boxer.id} with #{updatedAt}"
        boxer.lastUpdatedAt = updatedAt
        logger.debug "Finished updating #{@boxers[message.id].lastUpdatedAt}"
      else
        @boxers[message.id] = new Boxer(message.id, message.runtimes, message.freeMemory)
        logger.info "Received a boxer update: #{message.id}, number of boxers in my purview: #{_.keys(@boxers).length}"
    else if message.type == protocol.CreatedMessage.type ||
            message.type == protocol.StartedMessage.type ||
            message.type == protocol.StoppedMessage.type ||
            message.type == protocol.DestroyedMessage.type
      # Send a notification to Pusher
      # Call the web hook in action.io which updates the status of the box
      boxId = message.boxId
      ActionWebhook.sendNotification message, (err) ->
        if err
          logger.error "Error -> #{err} while sending notification"

  chooseBoxer: (runtime, memory) ->
    # Randomize the available boxer (if there is more than one available)
    availableBoxerIds = _.shuffle(_.keys(@boxers))
    self = this
    availableBoxer = null

    logger.info "Available Boxer IDs: #{availableBoxerIds}"

    _.each availableBoxerIds, (id) ->
      boxer = self.boxers[id]
      console.log "Value Of Updated At --> #{new Date().valueOf() - boxer.lastUpdatedAt}"

      if new Date().valueOf() - boxer.lastUpdatedAt >= Boxer.EXPIRY_TIME
        logger.debug "Expired Boxer: #{id}, deleting"
        self.boxers[id] = null
      else if (parseInt(boxer.freeMemory) > parseInt(memory) &&
               _.include(boxer.runtimes, runtime))
        availableBoxer = boxer

    availableBoxer

