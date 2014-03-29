BaseMessage = require './base_message'

module.exports = class CloneRepositoryMessage extends BaseMessage
  @type = 'aio:clone_repository'

  constructor: (attributes) ->
    @id = attributes.id
    @boxId = attributes.boxId
    @name = attributes.name
    @repositoryUrl = attributes.repositoryUrl
    @repositoryScm = attributes.repositoryScm
    super
