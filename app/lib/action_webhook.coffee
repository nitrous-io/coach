request = require 'superagent'
settings = require '../../config/settings'

module.exports = class ActionWebhook
  @sendNotification: (message, cb) ->
    request.put("#{settings.webhookHost}/boxes/#{message.boxId}/webhook")
           .send(payload: message.encode())
           .auth(settings.webhookUsername, settings.webhookPassword)
           .end (err, res) ->
             cb(err, res)
