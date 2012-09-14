express = require 'express'
settings = require './settings'

module.exports = (app) ->
  app.configure ->
    app.use express.cookieParser()
    app.use express.bodyParser()
    app.use express.methodOverride()
    app.use express.basicAuth (user, pass) ->
      user == settings.username && pass == settings.password
