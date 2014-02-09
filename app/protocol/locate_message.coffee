BaseMessage = require('./base_message')

module.exports = class LocateMessage extends BaseMessage
  @type = 'aio:locate'

  constructor: (attributes) ->
    super
