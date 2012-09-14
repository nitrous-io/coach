request = require 'superagent'
settings = require '../../config/settings'

module.exports = class ActionWebhook
  @sendNotification: (message, cb) ->
    request.put("#{settings.webhookHost}/boxes/#{message.boxId}/webhook")
           .send(payload: message.encode())
           .set('X-SECRET': settings.webhookSecret)
           .end (err, res) ->
             cb(err, res)
