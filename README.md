# Coach

Coach sits between the web API and the boxers and orchestrates the creation
of boxes. It listens to web requests from the web app, and sends messages to
the boxers.

## Dependencies

* This needs Redis Server running - remember to configure the host/port in
  [config/settings.coffee](config/settings.coffee), otherwise you might crap
  on your Redis server that's running on the default port!
* This has a dependency on [boxer](action-io/boxer). Remember to
  `git submodule init` and `git submodule update` after you clone. The protocol
  and the message parser are re-used from the boxer project.
