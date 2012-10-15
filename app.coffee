process.env.NODE_ENV ?= 'development'

_ = require 'underscore'
settings = require './config/settings'
BoxerListener = require './app/lib/boxer_listener'
logger = require './app/lib/logger'

express = require 'express'
app = express()

# settings
env = app.settings.env
_.extend app.settings, settings

# express config
require('./config/application')(app)

# routes
require('./config/routes')(app)

# uncaught exception handler
if env == 'production' || env == 'staging'
  airbrake = require('airbrake').createClient(app.settings.airbrakeKey)
  airbrake.handleExceptions()

# boxer listener
boxerListener = new BoxerListener(settings)
boxerListener.run()

if require.main == module || require.main.filename.match /boot\.js/
  server = app.listen(process.env.PORT || 4000)
  unless address = server.address()
    logger.info 'Could not start coach!'
    return

  logger.info "coach listening on port #{address.port} in #{env} mode"

module.exports =
                app: app
                boxerListener: boxerListener
