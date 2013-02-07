winston = require 'winston'
env = process.env.NODE_ENV

config =
  levels:
    info: 2
    warn: 5
    debug: 5
    error: 6
  colors:
    info: 'green'
    warn: 'yellow'
    debug: 'blue'
    error: 'red'

transports = if env == 'test'
  [
    new winston.transports.File
                              filename: "log/test.log"
                              json: false
                              timestamp: true
  ]
else
  [
    new winston.transports.Console colorize: true
    new winston.transports.File
                              filename: "log/coach.log"
                              json: false
                              timestamp: true
                              handleExceptions: true
  ]


logger = module.exports = new winston.Logger
                                        transports: transports,
                                        levels: config.levels
                                        colors: config.colors

