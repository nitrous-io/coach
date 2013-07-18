BoxerListener = require '../../app/lib/boxer_listener'
ActionWebhook = require '../../app/lib/action_webhook'
MessageParser = require '../../app/lib/message_parser'
settings = require '../../config/settings'
protocol = require '../../app/protocol'
_ = require 'underscore'

describe 'BoxerListener', ->
  boxerListener = null
  beforeEach -> boxerListener = new BoxerListener(settings)

  describe '#_handle', ->
    message = null

    context 'when message is a migrate message', ->
      beforeEach ->
        message = new protocol.MigrateMessage(success: true)
        message.type = "aio:migrate"
        sinon.stub ActionWebhook, "sendNotification"
        sinon.stub boxerListener.publisher, "publish"

      afterEach ->
        ActionWebhook.sendNotification.restore()
        boxerListener.publisher.publish.restore()

      context 'when message is not success', ->
        beforeEach -> message.success = false

        it 'sends a failed aio:migrated to the webhook', ->
          boxerListener._handle message
          calledMessage = ActionWebhook.sendNotification.lastCall.args[0]
          expect(calledMessage.type).to.eql "aio:migrated"
          expect(calledMessage.success).to.be.false

      context 'when message is migrate:snapshotted', ->
        beforeEach ->
          message.dataType = 'aio:migrate:snapshotted'
          message.snapshotURL = 's3-url'

        it 'pass the message as aio:migrate:create to boxer', ->
          boxerListener._handle message
          args = boxerListener.publisher.publish.lastCall.args
          channel = args[0]
          calledMessage = MessageParser.decode args[1]
          expect(channel).to.eql settings.boxerChannel
          expect(calledMessage.dataType).to.eql "aio:migrate:create"
          expect(calledMessage.snapshotURL).to.eql "s3-url"

      context 'when message is migrate:migrated', ->
        beforeEach ->
          message.id = 'new-host'
          message.port = 6666
          message.dataType = 'aio:migrate:created'

        it 'pass the message as aio:migrate:create to boxer with the excluded hosts', ->
          boxerListener._handle message
          calledMessage = ActionWebhook.sendNotification.lastCall.args[0]
          expect(calledMessage.type).to.eql "aio:migrated"
          expect(calledMessage.success).to.be.true
          expect(calledMessage.id).to.eql "new-host"
          expect(calledMessage.port).to.eql 6666

  describe 'chooseBoxer', ->
    beforeEach -> sinon.stub Date.prototype, 'valueOf', -> 1347606908660
    afterEach -> Date.prototype.valueOf.restore()

    context 'when only one boxer is available', ->
      boxer1 = null

      beforeEach ->
        boxer1 = newBoxer('boxer-1',
                          ['ruby', 'php', 'python'],
                          2048,
                          new Date().valueOf() - 1)

        boxerListener.boxers[boxer1.id] = boxer1

      it 'should return the only boxer available', ->
        availableBoxer = boxerListener.chooseBoxer('ruby', 256)
        expect(availableBoxer.id).to.eql 'boxer-1'
        expect(availableBoxer.freeMemory).to.eql 2048
        expect(availableBoxer.runtimes).to.eql ['ruby', 'php', 'python']

    context 'when there is one boxer available (but another is not available because it\'s "expired")', ->
      boxer1 = boxer2 = null

      beforeEach ->
        boxer1 = newBoxer('boxer-1',
                          ['ruby', 'php', 'python'],
                          2048,
                          new Date().valueOf() - (1 * 1000))

        boxer2 = newBoxer('boxer-2',
                          ['ruby']
                          1024,
                          new Date().valueOf() - (20 * 1000))
        boxerListener.boxers[boxer1.id] = boxer1
        boxerListener.boxers[boxer2.id] = boxer2

      it 'should return the boxer1 which has been updated most recently', ->
        availableBoxer = boxerListener.chooseBoxer('ruby', 256)
        expect(availableBoxer.id).to.eql 'boxer-1'
        expect(availableBoxer.freeMemory).to.eql 2048
        expect(availableBoxer.runtimes).to.eql ['ruby', 'php', 'python']

        expect(boxerListener.boxers['boxer-2']).to.be.null

    context 'when there is one boxer available (but another is not available because it doesn\'t support it\'s runtime)', ->
      boxer1 = boxer2 = null

      beforeEach ->
        boxer1 = newBoxer('boxer-1',
                          ['php', 'python'],
                          2048,
                          new Date().valueOf() - (1 * 1000))

        boxer2 = newBoxer('boxer-2',
                          ['ruby']
                          1024,
                          new Date().valueOf() - (2 * 1000))
        boxerListener.boxers[boxer1.id] = boxer1
        boxerListener.boxers[boxer2.id] = boxer2

      it 'should return the boxer1 which has been updated most recently', ->
        availableBoxer = boxerListener.chooseBoxer('ruby', 256)
        expect(availableBoxer.id).to.eql 'boxer-2'
        expect(availableBoxer.freeMemory).to.eql 1024
        expect(availableBoxer.runtimes).to.eql ['ruby']

    context 'when there is one boxer available (but another is not available because it doesn\'t have as much free memory)', ->
      boxer1 = boxer2 = null

      beforeEach ->
        boxer1 = newBoxer('boxer-1',
                          ['ruby', 'php', 'python'],
                          2048,
                          new Date().valueOf() - (1 * 1000))

        boxer2 = newBoxer('boxer-2',
                          ['ruby']
                          128,
                          new Date().valueOf() - (2 * 1000))
        boxerListener.boxers[boxer1.id] = boxer1
        boxerListener.boxers[boxer2.id] = boxer2

      it 'should return the boxer1 which has been updated most recently', ->
        availableBoxer = boxerListener.chooseBoxer('ruby', 256)
        expect(availableBoxer.id).to.eql 'boxer-1'
        expect(availableBoxer.freeMemory).to.eql 2048
        expect(availableBoxer.runtimes).to.eql ['ruby', 'php', 'python']

    context 'when there is more than one boxer available', ->
      boxer1 = boxer2 = null

      beforeEach ->
        boxer1 = newBoxer('boxer-1',
                          ['ruby', 'php', 'python'],
                          2048,
                          new Date().valueOf() - (1 * 1000))

        boxer2 = newBoxer('boxer-2',
                          ['ruby']
                          1024,
                          new Date().valueOf() - (2 * 1000))

        boxerListener.boxers[boxer1.id] = boxer1
        boxerListener.boxers[boxer2.id] = boxer2

      it 'should return the boxer1 which has been updated most recently', ->
        # Since we are randomly picking one from the eligible list,
        # we are only checking if it is picked from the list
        availableBoxer = boxerListener.chooseBoxer('ruby', 256)
        expect(_.include(boxerListener.boxers, availableBoxer)).to.be.true

    context 'when we want to exclude some boxers', ->
      boxer1 = boxer2 = null

      beforeEach ->
        boxer1 = newBoxer('boxer-1',
                          ['ruby', 'php', 'python'],
                          2048,
                          new Date().valueOf() - (1 * 1000))

        boxer2 = newBoxer('boxer-2',
                          ['ruby']
                          1024,
                          new Date().valueOf() - (2 * 1000))

        boxerListener.boxers[boxer1.id] = boxer1
        boxerListener.boxers[boxer2.id] = boxer2

      it 'does not choose from those boxers', ->
        availableBoxer = boxerListener.chooseBoxer('ruby', 256, 1024, excluded: ['boxer-1'])
        expect(availableBoxer.id).to.be.eql 'boxer-2'

        availableBoxer = boxerListener.chooseBoxer('ruby', 256, 1024, excluded: ['boxer-1', 'boxer-2'])
        expect(availableBoxer).to.be.nil

