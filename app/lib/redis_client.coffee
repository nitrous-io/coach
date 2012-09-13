redis = require 'redis'

settings = require('../../config/settings').redisMQ

client = redis.createClient(settings.port, settings.host)
client.auth(settings.password) if settings.password?
client.select(settings.database)

module.exports = client
