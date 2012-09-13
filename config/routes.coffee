to = require '../app/lib/route_to'
c = require '../app/controllers'

module.exports = (app) ->
  app.post   '/boxes',                to c.BoxesController, 'create'
  app.put    '/boxes/:name/start',    to c.BoxesController, 'start'
  app.put    '/boxes/:name/stop',     to c.BoxesController, 'stop'
  app.put    '/boxes/:name/destroy',  to c.BoxesController, 'destroy'
