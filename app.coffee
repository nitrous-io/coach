process.env.NODE_ENV ?= 'development'

_ = require 'underscore'

express = require 'express'
app = express()

# settings
env = app.settings.env
_.extend app.settings, require './config/settings'

# express config
require('./config/application')(app)

# routes
require('./config/routes')(app)

# uncaught exception handler
if env == 'production'
  process.on 'uncaughtException', (err) ->
    console.log err

if require.main == module || require.main.filename.match /boot\.js/
  server = app.listen(process.env.PORT || 4000)
  unless address = server.address()
    console.log 'Could not start coach!'
    return

  console.log "coach listening on port %d in %s mode", address.port, env

module.exports = app
