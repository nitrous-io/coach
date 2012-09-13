# Coach

The Coach is the one which sits in between the web API and the boxers
and orchestrates the creation of boxes. It listens to web requests from
the web app, and sends messages to the boxers

## Dependencies

* This needs Redis Server running (remember to change the host/port in
  config/settings.coffee if you change the default Redis settings)
* This has a dependency on boxer. Remember to ```git submodule init```
  and ```git submodule update``` after you clone. The protocol and the
message parser are re-used from the boxer project.
