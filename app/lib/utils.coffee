module.exports =
  escapeShellArg: (string) ->
    if typeof string == 'number'
      return "'#{string.toString()}'"
    if typeof string == 'string'
      return "'" + string.replace(/'/g, "'\"'\"'") + "'"
    null

  initRedisClientWith: (settings, clientName = "") ->
    client = null

    if settings
      client = require('redis').createClient(settings.port, settings.host)
      client.auth(settings.password) if settings.password?
      client.select(settings.database)
      # Catch errors which will cause the Redis client to reconnect
      # without killing the process
      if process.env.NODE_ENV != 'test'
        client.on 'error', (err) -> console.log "Redis Error on client: #{clientName}: ", err

    client

  initAirbrakeClient: (airbrakeAPIKey) ->
    airbrakeClient = null

    if airbrakeAPIKey
      airbrakeClient = require('airbrake').createClient airbrakeAPIKey

    airbrakeClient

