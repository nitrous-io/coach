process.env.NODE_ENV ?= 'development'
process.title = "coach"

_                   = require 'underscore'
settings            = require './config/settings'
BoxerListener       = require './app/lib/boxer_listener'
initRedisClientWith = require('./app/lib/utils').initRedisClientWith
log                 = require('./app/lib/log')

express = require 'express'
app = express()

# settings
env = app.settings.env
_.extend app.settings, settings

# express config
require('./config/application')(app)

# routes
require('./config/routes')(app)

if app.settings.airbrakeAPIKey
  airbrake = require('airbrake').createClient app.settings.airbrakeAPIKey
  airbrake.handleExceptions() # Don't die when exceptions occur

# send uptime/memory usage data to statsd
Repoman = require('repoman')
(new Repoman).collect()

# boxer listener
boxerListener = new BoxerListener(settings)
boxerListener.run()

if require.main == module || require.main.filename.match /boot\.js/
  server = app.listen(process.env.PORT || 4000)
  unless address = server.address()
    log 'Could not start coach!'
    return

  log "coach listening on port #{address.port} in #{env} mode"

module.exports =
                app: app
                boxerListener: boxerListener
