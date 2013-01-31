_ = require 'underscore'
env = process.env.NODE_ENV

settings =
  common:
    boxerChannel: 'aio-boxer-channel'
    coachChannel: 'aio-coach-channel'
    bombayChannel: 'aio-bombay-channel'
    redisMQ:
      host: process.env.REDIS_HOST
      port: process.env.REDIS_PORT
      password: null
      database: 0
    webhookHost: process.env.WEBHOOK_HOST
    webhookUsername: process.env.WEBHOOK_USERNAME
    webhookPassword: process.env.WEBHOOK_PASSWORD
    username: process.env.COACH_USERNAME
    password: process.env.COACH_PASSWORD
    airbrakeAPIKey: process.env.AIRBRAKE_API_KEY
  development: {}
  test:
    redisMQ:
      host: '0.0.0.0'
      port: 6379
      password: null
      database: 0
    webhookHost: 'http://127.0.0.1:3306'
    webhookUsername: 'aio'
    webhookPassword: 'foobar'
    username: 'aio'
    password: 'foobar'
  production: {}

module.exports = _.extend settings.common, settings[env]
