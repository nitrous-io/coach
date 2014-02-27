BaseMessage = require('./base_message')
os = require 'os'

module.exports = class AdvertiseMessage extends BaseMessage
  @type: 'aio:advertise'

  @construct: ->
    settings = require '../../config/settings'
    runtimes = Object.keys(settings.runtimes)

    return new AdvertiseMessage(id: settings.id, runtimes: runtimes, freeMemory: os.freemem())

  constructor: (attributes) ->
    @id = attributes.id
    @runtimes = attributes.runtimes
    @freeMemory = attributes.freeMemory
    @cpus = attributes.cpus
    @boxStats = attributes.boxStats
    super
