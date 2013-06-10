request = require 'superagent'
retry = require 'retry'
settings = require '../../config/settings'

module.exports = class ActionWebhook
  # The amount of time before starting the first retry
  @MIN_TIMEOUT = 1 * 1000
  # The maximum amount of time between two retries
  @MAX_TIMEOUT = 30  * 1000
  # The maximum amount of times to retry the operation
  @MAX_RETRIES = 50
  # The exponential factor to use
  @FACTOR = 2
  # Time between retries is calculated like this:
  # Math.min(random * minTimeout * Math.pow(factor, attempt), maxTimeout);
  # From: https://github.com/tim-kos/node-retry/blob/master/Readme.md

  @sendNotification: (message, cb) ->
    operation = retry.operation
                                retries: @MAX_RETRIES
                                factor: @FACTOR
                                minTimeout: @TIMEOUT
                                maxTimeout: @MAX_TIMEOUT

    operation.attempt (currentAttempt) ->
      url = "#{settings.webhookHost}/boxes/#{message.boxId}/webhook"
      console.log "Sent to #{url} ", message

      request.put(url)
             .send(payload: message.encode())
             .auth(settings.webhookUsername, settings.webhookPassword)
             .end (err, res) ->
               # If there is no err but res.status returns something other than 200
               # then it's an error and there needs to be a retry
               if !err && res.status != 200
                 err = new Error("Error Thrown for #{url}: #{res.status}")

               if operation.retry(err)
                 return

               if err
                 cb(operation.mainError(), res)
               else
                 cb(null, res)
