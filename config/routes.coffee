to = require '../app/lib/route_to'
c = require '../app/controllers'

module.exports = (app) ->
  app.post   '/boxes',                to c.BoxesController, 'create'
  app.put    '/boxes/:name/start',    to c.BoxesController, 'start'
  app.put    '/boxes/:name/stop',     to c.BoxesController, 'stop'
  app.put    '/boxes/:name/restart',  to c.BoxesController, 'restart'
  app.put    '/boxes/:name/destroy',  to c.BoxesController, 'destroy'
  app.put    '/boxes/:name/snapshot', to c.BoxesController, 'snapshot'
  app.put    '/boxes/:name',          to c.BoxesController, 'update'

  app.put    '/boxes/:name/restore_snapshot', to c.BoxesController, 'restore_snapshot'
  app.put    '/boxes/:name/delete_snapshot', to c.BoxesController, 'deleteSnapshot'
  app.put    '/boxes/:name/archive', to c.BoxesController, 'archive'
