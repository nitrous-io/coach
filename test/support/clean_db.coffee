redis = require 'redis'

module.exports = (cb) ->
  storeSettings = require('../../config/settings').redisStore

  cleanerClient = redis.createClient(storeSettings.port, storeSettings.host)
  cleanerClient.auth(storeSettings.password) if storeSettings.password?
  cleanerClient.select(storeSettings.database)

  cleanerClient.flushall ->
    client = redis.createClient(storeSettings.port, storeSettings.host)
    client.auth(storeSettings.password) if storeSettings.password?
    client.select(storeSettings.database)
    cb()

