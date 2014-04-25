util = require 'util'
log = require './log'

module.exports = routeTo = (controllerClass, action) ->
  (req, res) ->
    startTime = Date.now()
    controller = new controllerClass(req, res)
    controllerAndAction = "#{controllerClass.name}##{action}"
    if process.env.NODE_ENV != 'test'
      msg = [
        "Started #{req.method} \"#{req.url}\" for #{req.headers['x-forwarded-for'] || req.connection.remoteAddress} at #{new Date}",
        "Processing by #{controllerAndAction}",
        "Params: #{util.format("%j", controller.params)}"
      ].join " "
      log msg

    logDuration = ->
      log "#{controllerAndAction}: #{(Date.now() - startTime) / 1000.0}"
    res.on 'finish', logDuration
    res.on 'close', logDuration
    controller[action]()
