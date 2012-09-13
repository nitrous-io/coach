redis = require 'redis'

module.exports = (cb) ->
  settings = require('../../config/settings').redisMQ

  cleanerClient = redis.createClient(settings.port, settings.host)
  cleanerClient.auth(settings.password) if settings.password?
  cleanerClient.select(settings.database)

  cleanerClient.flushall ->
    cb()

