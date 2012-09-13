process.env.NODE_ENV ?= 'development'

_ = require 'underscore'

# uncaught exception handler
if process.env.NODE_ENV == 'production'
  process.on 'uncaughtException', (err) ->
    console.log err

console.log "Started Coach"
