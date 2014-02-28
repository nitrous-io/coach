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

    context 'when message is a migrated message', ->
      beforeEach ->
        message = new protocol.MigratedMessage(success: true)
        message.type = "aio:migrated"
        sinon.stub ActionWebhook, "sendNotification"

      afterEach ->
        ActionWebhook.sendNotification.restore()

      context 'when message is not success', ->
        beforeEach -> message.success = false

        it 'sends a failed aio:migrated to the webhook', ->
          boxerListener._handle message
          calledMessage = ActionWebhook.sendNotification.lastCall.args[0]
          expect(calledMessage.type).to.eql "aio:migrated"
          expect(calledMessage.success).to.be.false

      context 'when message is success', ->
        beforeEach -> message.success = true

        it 'sends a success aio:migrated to the webhook', ->
          boxerListener._handle message
          calledMessage = ActionWebhook.sendNotification.lastCall.args[0]
          expect(calledMessage.type).to.eql "aio:migrated"
          expect(calledMessage.success).to.be.true

  describe 'chooseBoxer', ->
    beforeEach -> sinon.stub Date.prototype, 'valueOf', -> 1347606908660
    afterEach -> Date.prototype.valueOf.restore()

    context 'when only one boxer is available', ->
      boxer1 = null

      beforeEach ->
        boxer1 = newBoxer('boxer-1',
                          ['ruby', 'php', 'python'],
                          new Date().valueOf() - 1)

        boxerListener.boxers[boxer1.id] = boxer1

      it 'should return the only boxer available', ->
        availableBoxer = boxerListener.chooseBoxer(runtime: 'ruby')
        expect(availableBoxer.id).to.eql 'boxer-1'
        expect(availableBoxer.runtimes).to.eql ['ruby', 'php', 'python']

    context "when there is one boxer available (but another is not available because it's 'expired')", ->
      boxer1 = boxer2 = null

      beforeEach ->
        boxer1 = newBoxer('boxer-1',
                          ['ruby', 'php', 'python'],
                          new Date().valueOf() - (1 * 1000))

        boxer2 = newBoxer('boxer-2',
                          ['ruby']
                          new Date().valueOf() - (20 * 1000))
        boxerListener.boxers[boxer1.id] = boxer1
        boxerListener.boxers[boxer2.id] = boxer2

      it 'should return the boxer that has not expired', ->
        availableBoxer = boxerListener.chooseBoxer(runtime: 'ruby')
        expect(availableBoxer.id).to.eql 'boxer-1'
        expect(availableBoxer.runtimes).to.eql ['ruby', 'php', 'python']

        expect(boxerListener.boxers['boxer-2']).to.be.undefined

    context "when there is one boxer available (but another is not available because it doesn't support its runtime)", ->
      boxer1 = boxer2 = null

      beforeEach ->
        boxer1 = newBoxer('boxer-1',
                          ['php', 'python'],
                          new Date().valueOf() - (1 * 1000))

        boxer2 = newBoxer('boxer-2',
                          ['ruby'],
                          new Date().valueOf() - (2 * 1000))
        boxerListener.boxers[boxer1.id] = boxer1
        boxerListener.boxers[boxer2.id] = boxer2

      it 'should return the boxer that supports the required runtime', ->
        availableBoxer = boxerListener.chooseBoxer(runtime: 'ruby')
        expect(availableBoxer.id).to.eql 'boxer-2'
        expect(availableBoxer.runtimes).to.eql ['ruby']

    context 'when there is no runtime requirement', ->
      boxer1 = boxer2 = null

      beforeEach ->
        boxer1 = newBoxer('boxer-1', [], new Date().valueOf() - (1 * 1000))
        boxer2 = newBoxer('boxer-2', [], new Date().valueOf() - (2 * 1000))
        boxerListener.boxers[boxer1.id] = boxer1
        boxerListener.boxers[boxer2.id] = boxer2

      context 'when a snapshotId is given', ->
        it 'should return any one of the boxers', ->
          availableBoxer = boxerListener.chooseBoxer(snapshotId: 123)
          expect(_.include(boxerListener.boxers, availableBoxer)).to.be.true

          delete boxerListener.boxers[boxer1.id]
          availableBoxer = boxerListener.chooseBoxer(snapshotId: 123)
          expect(availableBoxer.id).to.eql 'boxer-2'

      context 'when no snapshotId is given', ->
        it 'should not return any boxer', ->
          availableBoxer = boxerListener.chooseBoxer()
          expect(availableBoxer).to.be.null

    context 'when there is more than one boxer available', ->
      boxer1 = boxer2 = null

      beforeEach ->
        boxer1 = newBoxer('boxer-1',
                          ['ruby', 'php', 'python'],
                          new Date().valueOf() - (1 * 1000))

        boxer2 = newBoxer('boxer-2',
                          ['ruby'],
                          new Date().valueOf() - (2 * 1000))

        boxerListener.boxers[boxer1.id] = boxer1
        boxerListener.boxers[boxer2.id] = boxer2

      it 'should return any one of the boxers', ->
        # Since we are randomly picking one from the eligible list,
        # we are only checking if it is picked from the list
        availableBoxer = boxerListener.chooseBoxer(runtime: 'ruby')
        expect(_.include(boxerListener.boxers, availableBoxer)).to.be.true

    describe '#scoreBoxers', ->
      context 'when all boxers have a "running boxes" statistic', ->
        boxer1 = boxer2 = boxer3 = boxers = null

        beforeEach ->
          boxer1 = newBoxer('boxer-1',
                            ['ruby'],
                            new Date().valueOf() - (1 * 1000),
                            { running: 50 })
          boxer2 = newBoxer('boxer-2',
                            ['ruby'],
                            new Date().valueOf() - (2 * 1000),
                            { running: 20 })
          boxer3 = newBoxer('boxer-3',
                            ['ruby'],
                            new Date().valueOf() - (3 * 1000),
                            { running: 30 })
          boxers = [boxer1, boxer2, boxer3]

        it 'should return a list of objects with the respective boxers and an expected score', ->
          result = boxerListener.scoreBoxers(boxers)

          expect(result[0].boxer).to.eql boxer1
          expect(result[0].score).to.eql 0.5 # Score is computed by: (total running - boxer running) / total running.
          expect(result[1].boxer).to.eql boxer2
          expect(result[1].score).to.eql 0.8
          expect(result[2].boxer).to.eql boxer3
          expect(result[2].score).to.eql 0.7

      context 'when not all boxes have a "running boxes" statistic', ->
        boxer1 = boxer2 = boxers = null

        beforeEach ->
          boxer1 = newBoxer('boxer-1',
                            ['ruby'],
                            new Date().valueOf() - (1 * 1000),
                            { running: 50 })
          boxer2 = newBoxer('boxer-2',
                            ['ruby'],
                            new Date().valueOf() - (2 * 1000),
                            {})
          boxers = [boxer1, boxer2]

        it 'should return a list of objects with the respective boxers and a score of 0', ->
          result = boxerListener.scoreBoxers(boxers)

          expect(result[0].boxer).to.eql boxer1
          expect(result[0].score).to.eql 0
          expect(result[1].boxer).to.eql boxer2
          expect(result[1].score).to.eql 0

    describe '#sortByScore', ->
      it 'should sort a list by score, with the item with the highest score in front', ->
        item1 = { score: 5 }
        item2 = { score: 1 }
        item3 = { score: 10 }
        expect(boxerListener.sortByScore([item1, item2, item3])).to.eql [item3, item1, item2]
