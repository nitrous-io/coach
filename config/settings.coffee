_ = require 'underscore'
env = process.env.NODE_ENV

settings =
  common:
    boxerChannel: 'aio-boxer-channel'
    coachChannel: 'aio-coach-channel'
  development:
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
  staging:
    airbrakeKey: '9a8772055e3636c9f0828d23c9eb83f4'
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
  production:
    airbrakeKey: '3716dd9e7f7c20f1b59170cc937ae7a6'
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

module.exports = _.extend settings.common, settings[env]
