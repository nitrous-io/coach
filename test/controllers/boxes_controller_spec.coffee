MessageParser = require '../../app/lib/message_parser'
initRedisClientWith = require('../../app/lib/utils').initRedisClientWith

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

    it 'responds with 202', (done) ->
      # TODO: Write Specs for when a boxer is not available
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

            done()

          request(app)
            .post('/boxes')
            .send('box': {'name':'mclovin','id':'1','runtime':'ruby','memory':'256','disk_space':'2048'})
            .expect(202)
            .end (err, res) ->
              resultObject = JSON.parse(res.text)
              expect(resultObject.status).to.eql "OK"
              expect(resultObject.text).to.eql 1


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
              expect(resultObject.text).to.eql 1

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
              expect(resultObject.text).to.eql 1

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
              expect(resultObject.text).to.eql 1

