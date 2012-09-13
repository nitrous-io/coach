_ = require 'underscore'
env = process.env.NODE_ENV

settings =
  common:
    boxerChannel: 'aio-boxer-channel'
    coachChannel: 'aio-coach-channel'
  development:
    redisMQ:
      host: '0.0.0.0'
      port: 6379
      password: null
      database: 0
  test:
    redisMQ:
      host: '0.0.0.0'
      port: 6379
      password: null
      database: 0
  production:
    redisMQ:
      host: '0.0.0.0'
      port: 6379
      password: null
      database: 0

module.exports = _.extend settings.common, settings[env]

