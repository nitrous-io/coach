request = require 'superagent'
settings = require '../../config/settings'
logger = require './logger'

module.exports = class ActionWebhook
  @sendNotification: (message, cb) ->
    url = "#{settings.webhookHost}/boxes/#{message.boxId}/webhook"
    logger.debug "Sending #{message} to #{url}"

    request.put(url)
           .send(payload: message.encode())
           .auth(settings.webhookUsername, settings.webhookPassword)
           .end (err, res) ->
             cb(err, res)
