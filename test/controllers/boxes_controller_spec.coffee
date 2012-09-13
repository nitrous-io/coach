MessageParser = require '../../app/lib/message_parser'
initRedisClientWith = require('../../app/lib/utils').initRedisClientWith
boxerListener = require('../../app').boxerListener

describe 'BoxesController', ->
  boxer = settings = null

  describe 'POST create', ->
    beforeEach (done) ->
      settings = require '../../config/settings'
      boxer = initRedisClientWith(settings.redisMQ)
      boxer.subscribe settings.boxerChannel, (err, result) ->
        done() if !err

    afterEach ->
      boxer.unsubscribe()
      boxer = null

    context 'boxer is not present', ->
      beforeEach ->
        sinon.stub boxerListener, 'chooseBoxer', (runtime, memory, diskSpace) ->
          null

      afterEach ->
        boxerListener.chooseBoxer.restore()

      it 'responds with 202', (done) ->
        request(app)
          .post('/boxes')
          .send('box': {'name':'mclovin','id':'1','runtime':'ruby','memory':'256','disk_space':'2048'})
          .expect(404)
          .end (err, res) ->
            resultObject = JSON.parse(res.text)
            expect(resultObject.status).to.eql "MISSING"
            done()

    context 'boxer is present', ->
      beforeEach ->
        sinon.stub boxerListener, 'chooseBoxer', (runtime, memory, diskSpace) ->
          id: 'boxer-id'

      afterEach ->
        boxerListener.chooseBoxer.restore()

      it 'responds with 202', (done) ->
        boxer.subscribe settings.boxerChannel, (err, result) ->
          if !err
            boxer.on 'message', (channel, rawMessage) ->
              parsedMessage = JSON.parse(rawMessage)
              expect(parsedMessage.name).to.eql 'mclovin'
              expect(parsedMessage.boxId).to.eql '1'
              expect(parsedMessage.runtime).to.eql 'ruby'
              expect(parsedMessage.memory).to.eql '256'
              expect(parsedMessage.diskSpace).to.eql '2048'
              expect(parsedMessage.type).to.eql 'aio.create'
              expect(parsedMessage.id).to.eql 'boxer-id'

              done()

            request(app)
              .post('/boxes')
              .send('box': {'name':'mclovin','id':'1','runtime':'ruby','memory':'256','disk_space':'2048'})
              .expect(202)
              .end (err, res) ->
                resultObject = JSON.parse(res.text)
                expect(resultObject.status).to.eql "OK"


  describe 'PUT start', ->
    beforeEach (done) ->
      settings = require '../../config/settings'
      boxer = initRedisClientWith(settings.redisMQ)
      boxer.subscribe settings.boxerChannel, (err, result) ->
        done() if !err

    afterEach ->
      boxer.unsubscribe()
      boxer = null

    it 'responds with 202', (done) ->
      boxer.subscribe settings.boxerChannel, (err, result) ->
        if !err
          boxer.on 'message', (channel, rawMessage) ->
            parsedMessage = JSON.parse(rawMessage)
            expect(parsedMessage.name).to.eql 'mclovin'
            expect(parsedMessage.id).to.eql 'boxer-id'
            expect(parsedMessage.type).to.eql 'aio.start'

            done()

          request(app)
            .put('/boxes/mclovin/start')
            .send('box': {'boxer_id':'boxer-id'})
            .expect(202)
            .end (err, res) ->
              resultObject = JSON.parse(res.text)
              expect(resultObject.status).to.eql "OK"

  describe 'PUT stop', ->
    beforeEach (done) ->
      settings = require '../../config/settings'
      boxer = initRedisClientWith(settings.redisMQ)
      boxer.subscribe settings.boxerChannel, (err, result) ->
        done() if !err

    afterEach ->
      boxer.unsubscribe()
      boxer = null

    it 'responds with 202', (done) ->
      boxer.subscribe settings.boxerChannel, (err, result) ->
        if !err
          boxer.on 'message', (channel, rawMessage) ->
            parsedMessage = JSON.parse(rawMessage)
            expect(parsedMessage.name).to.eql 'mclovin'
            expect(parsedMessage.id).to.eql 'boxer-id'
            expect(parsedMessage.type).to.eql 'aio.stop'

            done()

          request(app)
            .put('/boxes/mclovin/stop')
            .send('box': {'boxer_id':'boxer-id'})
            .expect(202)
            .end (err, res) ->
              resultObject = JSON.parse(res.text)
              expect(resultObject.status).to.eql "OK"

  describe 'PUT destroy', ->
    beforeEach (done) ->
      settings = require '../../config/settings'
      boxer = initRedisClientWith(settings.redisMQ)
      boxer.subscribe settings.boxerChannel, (err, result) ->
        done() if !err

    afterEach ->
      boxer.unsubscribe()
      boxer = null

    it 'responds with 202', (done) ->
      boxer.subscribe settings.boxerChannel, (err, result) ->
        if !err
          boxer.on 'message', (channel, rawMessage) ->
            parsedMessage = JSON.parse(rawMessage)
            expect(parsedMessage.name).to.eql 'mclovin'
            expect(parsedMessage.id).to.eql 'boxer-id'
            expect(parsedMessage.type).to.eql 'aio.destroy'

            done()

          request(app)
            .put('/boxes/mclovin/destroy')
            .send('box': {'boxer_id':'boxer-id'})
            .expect(202)
            .end (err, res) ->
              resultObject = JSON.parse(res.text)
              expect(resultObject.status).to.eql "OK"

