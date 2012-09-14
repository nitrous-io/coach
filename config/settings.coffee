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
    webhookHost: 'http://127.0.0.1'
    webhookSecret: 'foobar'
  test:
    redisMQ:
      host: '0.0.0.0'
      port: 6379
      password: null
      database: 0
    webhookHost: 'http://127.0.0.1:3306'
    webhookSecret: 'foobar'
  production:
    redisMQ:
      host: '0.0.0.0'
      port: 6379
      password: null
      database: 0
    webhookHost: 'https://www.action.io'
    webhookSecret: 'foobar'

module.exports = _.extend settings.common, settings[env]

