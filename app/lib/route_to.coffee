util = require 'util'
log = require './log'

module.exports = routeTo = (controllerClass, action) ->
  (req, res) ->
    controller = new controllerClass(req, res)
    if process.env.NODE_ENV != 'test'
      msg = [
        "Started #{req.method} \"#{req.url}\" for #{req.headers['x-forwarded-for'] || req.connection.remoteAddress} at #{new Date}",
        "Processing by #{controllerClass.name}##{action}",
        "Params: #{util.format("%j", controller.params)}"
      ].join " "
      log msg
    controller[action]()
