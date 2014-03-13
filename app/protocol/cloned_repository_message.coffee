BaseMessage = require './base_message'

module.exports = class ClonedRepositoryMessage extends BaseMessage
  @type = 'aio:cloned_repository'

  constructor: (attributes) ->
    @id = attributes.id
    @boxId = attributes.boxId
    @name = attributes.name
    @repositoryUrl = attributes.repositoryUrl
    @error = attributes.error
    @success = attributes.success
    super
