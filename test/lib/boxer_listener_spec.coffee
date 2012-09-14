BoxerListener = require '../../app/lib/boxer_listener'
settings = require '../../config/settings'
_ = require 'underscore'

describe 'BoxerListener', ->
  describe 'chooseBoxer', ->
    boxerListener = null
    beforeEach ->
      boxerListener = new BoxerListener(settings)
      sinon.stub Date.prototype, 'valueOf', ->
        return 1347606908660

    afterEach ->
      Date.prototype.valueOf.restore()

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
                          new Date().valueOf() - 1)

        boxer2 = newBoxer('boxer-2',
                          ['ruby']
                          1024,
                          new Date().valueOf() - 20)
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
                          new Date().valueOf() - 1)

        boxer2 = newBoxer('boxer-2',
                          ['ruby']
                          1024,
                          new Date().valueOf() - 2)
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
                          new Date().valueOf() - 1)

        boxer2 = newBoxer('boxer-2',
                          ['ruby']
                          128,
                          new Date().valueOf() - 2)
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
                          new Date().valueOf() - 1)

        boxer2 = newBoxer('boxer-2',
                          ['ruby']
                          1024,
                          new Date().valueOf() - 2)
        boxerListener.boxers[boxer1.id] = boxer1
        boxerListener.boxers[boxer2.id] = boxer2

      it 'should return the boxer1 which has been updated most recently', ->
        # Since we are randomly picking one from the eligible list,
        # we are only checking if it is picked from the list
        availableBoxer = boxerListener.chooseBoxer('ruby', 256)
        expect(_.include(boxerListener.boxers, availableBoxer)).to.be.true



