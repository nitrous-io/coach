BaseMessage = require './base_message'

module.exports = class ConfigureMessage extends BaseMessage
  @type = 'aio:configure'

  @dataTypes =
    'aio:configure:add_public_key': 'aio:configured:add_public_key'
    'aio:configure:remove_public_key': 'aio:configured:remove_public_key'
    'aio:configure:set_env_variables': 'aio:configured:set_env_variables'
    'aio:configure:remove_env_variables': 'aio:configured:remove_env_variables'
    'aio:configure:change_specs': 'aio:configured:change_specs'
    'aio:configure:update_auth': 'aio:configured:update_auth'
    'aio:configure:update_premium': 'aio:configured:update_premium'

  constructor: (attributes) ->
    @id = attributes.id
    @name = attributes.name
    @data = attributes.data
    if (ConfigureMessage.dataTypes[attributes.dataType])?
      @dataType = attributes.dataType
    super

