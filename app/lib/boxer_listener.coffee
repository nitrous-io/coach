MessageParser       = require './message_parser'
ActionWebhook       = require './action_webhook'
protocol            = require '../protocol'
initRedisClientWith = require('./utils').initRedisClientWith
_                   = require 'underscore'
log                 = require './log'

class Boxer
  @EXPIRY_TIME = 10 * 1000 # 10 seconds

  constructor: (attributes) ->
    @updateAttributes(attributes)

  updateAttributes: (attributes) ->
    @lastUpdatedAt = new Date().valueOf()
    @id = attributes.id
    @runtimes = attributes.runtimes
    @cpus = attributes.cpus
    @boxStats = attributes.boxStats

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
        boxer.updateAttributes(message)
      else
        @boxers[message.id] = new Boxer(message)
        log "Registered a new boxer: #{message.id}", message
        log "Number of boxers in my purview: #{_.keys(@boxers).length}"
    else if message.type == protocol.CreatedMessage.type ||
            message.type == protocol.StartedMessage.type ||
            message.type == protocol.StoppedMessage.type ||
            message.type == protocol.RestartedMessage.type ||
            message.type == protocol.DestroyedMessage.type ||
            message.type == protocol.ConfiguredMessage.type ||
            message.type == protocol.SnapshottedMessage.type ||
            message.type == protocol.DeletedSnapshotMessage.type ||
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
  # Supported requirements:
  #   * runtime - box runtime, e.g. 'ruby', 'golang'
  #   * snapshotId - ID of snapshot to use to create the box
  # Any unknown requirements will be ignored.
  chooseBoxer: (requirements) ->
    # Randomize the available boxer (if there is more than one available)
    availableBoxers = this._weightedBoxers()
    availableBoxer = null

    runtime = requirements?.runtime
    snapshotId = requirements?.snapshotId

    runtimeIndependent = snapshotId? and not runtime?

    log "Available Boxer IDs: #{_.map(availableBoxers, (v) -> v.id)}"

    _.each availableBoxers, (boxer) =>
      log "Boxer '#{boxer.id}': Value Of Updated At --> #{new Date().valueOf() - boxer.lastUpdatedAt}"

      if new Date().valueOf() - boxer.lastUpdatedAt >= Boxer.EXPIRY_TIME
        log "Error: Expired Boxer: #{boxer.id}, deleting"
        @boxers[boxer.id] = null
      else
        if runtimeIndependent || _.include(boxer.runtimes, runtime)
          availableBoxer = boxer

    availableBoxer

  _weightedBoxers: ->
    boxers = this.scoreBoxers(@boxers)
    boxers = this.sortByScore(boxers)

    log "Weighted boxers: #{_.map(boxers, (v) -> "#{v.boxer.id}(score: #{v.score})" )}"

    _.map(boxers, (v) -> v.boxer)

  # Takes a list of boxers and returns a list of
  # { boxer: boxer, score: score } after scoring each boxer.
  # We don't apply any randomness here so that we can test this reliably.
  # Callers can apply randomness to the scores as necessary.
  scoreBoxers: (boxers) ->
    if _.every(boxers, (boxer) -> boxer.boxStats?.running?)
      totalRunningBoxes = _.reduce(
        boxers
        (memo, boxer) -> memo + boxer.boxStats.running
        0)

    _.map boxers, (boxer) ->
      score = 0
      if totalRunningBoxes? and totalRunningBoxes != 0
        score += (totalRunningBoxes - boxer.boxStats.running) / totalRunningBoxes
      { boxer: boxer, score: score }

  # Sort a list of items by "score", with the highest score in front.
  sortByScore: (list) ->
    _.sortBy(list, (item) -> -item.score)
