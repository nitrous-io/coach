MessageParser = require '../../app/lib/message_parser'
initRedisClientWith = require('../../app/lib/utils').initRedisClientWith
boxerListener = require('../../app').boxerListener

describe 'BoxesController', ->
  boxer = settings = null

  describe 'POST create', ->
    beforeEach ->
      settings = require '../../config/settings'
      boxer = initRedisClientWith(settings.redisMQ)

    afterEach ->
      boxer.unsubscribe()
      boxer = null

    context 'boxer is not present', ->
      beforeEach ->
        sinon.stub boxerListener, 'chooseBoxer', (runtime, memory, diskSpace) ->
          null

      afterEach ->
        boxerListener.chooseBoxer.restore()

      it 'responds with 404', (done) ->
        request(app)
          .post('/boxes')
          .send('box': {'name':'mclovin','id':'1','runtime':'ruby','memory':'256','disk_space':'2048'})
          .auth('aio', 'foobar')
          .expect(404)
          .end (err, res) ->
            resultObject = JSON.parse(res.text)
            expect(resultObject.status).to.eql "MISSING"
            done()

    context 'boxer is present (valid params)', ->
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
              expect(parsedMessage.type).to.eql 'aio:create'
              expect(parsedMessage.id).to.eql 'boxer-id'
              expect(parsedMessage.publicKeys).to.eql ['public-key-1','public-key-2']
              expect(parsedMessage.sshKeyPair).to.eql {'public_key': 'public-key','private_key': 'private-key'}

              done()

            request(app)
              .post('/boxes')
              .auth('aio', 'foobar')
              .send('box': {
                'name':'mclovin',
                'id':'1',
                'runtime':'ruby',
                'memory':'256',
                'disk_space':'2048',
                'ssh_key_pair':"{\"public_key\":\"public-key\",\"private_key\":\"private-key\"}",
                'public_keys':'["public-key-1","public-key-2"]',''})
              .expect(202)
              .end (err, res) ->
                resultObject = JSON.parse(res.text)
                expect(resultObject.status).to.eql "OK"

    context 'boxer is present (invalid params)', ->
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
              expect(parsedMessage.type).to.eql 'aio:create'
              expect(parsedMessage.id).to.eql 'boxer-id'
              expect(parsedMessage.publicKeys).to.be.undefined

              done()

            request(app)
              .post('/boxes')
              .auth('aio', 'foobar')
              .send('box': {'name':'mclovin','id':'1','runtime':'ruby','memory':'256','disk_space':'2048','public_keys':'abc'})
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
            expect(parsedMessage.type).to.eql 'aio:start'

            done()

          request(app)
            .put('/boxes/mclovin/start')
            .send('box': {'boxer_id':'boxer-id'})
            .auth('aio', 'foobar')
            .expect(202)
            .end (err, res) ->
              resultObject = JSON.parse(res.text)
              expect(resultObject.status).to.eql "OK"

  describe 'PUT update', ->
    beforeEach (done) ->
      settings = require '../../config/settings'
      boxer = initRedisClientWith(settings.redisMQ)
      boxer.subscribe settings.boxerChannel, (err, result) ->
        done() if !err

    afterEach ->
      boxer.unsubscribe()
      boxer = null

    context 'adding a public key', ->
      it 'responds with 202', (done) ->
        boxer.subscribe settings.boxerChannel, (err, result) ->
          if !err
            boxer.on 'message', (channel, rawMessage) ->
              parsedMessage = JSON.parse(rawMessage)
              expect(parsedMessage.name).to.eql 'mclovin'
              expect(parsedMessage.id).to.eql 'boxer-id'
              expect(parsedMessage.type).to.eql 'aio:configure'
              expect(parsedMessage.dataType).to.eql 'aio:configure:add_public_key'
              expect(parsedMessage.data).to.eql 'public-key'

              done()

            request(app)
              .put('/boxes/mclovin')
              .auth('aio', 'foobar')
              .send('box': {'boxer_id':'boxer-id', 'data_type': 'aio:configure:add_public_key', 'data': 'public-key'})
              .expect(202)
              .end (err, res) ->
                resultObject = JSON.parse(res.text)
                expect(resultObject.status).to.eql "OK"

    context 'removing a public key', ->
      it 'responds with 202', (done) ->
        boxer.subscribe settings.boxerChannel, (err, result) ->
          if !err
            boxer.on 'message', (channel, rawMessage) ->
              parsedMessage = JSON.parse(rawMessage)
              expect(parsedMessage.name).to.eql 'mclovin'
              expect(parsedMessage.id).to.eql 'boxer-id'
              expect(parsedMessage.type).to.eql 'aio:configure'
              expect(parsedMessage.dataType).to.eql 'aio:configure:remove_public_key'
              expect(parsedMessage.data).to.eql 'public-key'

              done()

            request(app)
              .put('/boxes/mclovin')
              .auth('aio', 'foobar')
              .send('box': {'boxer_id':'boxer-id', 'data_type': 'aio:configure:remove_public_key', 'data': 'public-key'})
              .expect(202)
              .end (err, res) ->
                resultObject = JSON.parse(res.text)
                expect(resultObject.status).to.eql "OK"

    context 'setting env variables', ->
      it 'responds with 202', (done) ->
        boxer.subscribe settings.boxerChannel, (err, result) ->
          return done(err) if err
          boxer.on 'message', (channel, rawMessage) ->
            parsedMessage = JSON.parse(rawMessage)
            expect(parsedMessage.name).to.eql 'mclovin'
            expect(parsedMessage.id).to.eql 'boxer-id'
            expect(parsedMessage.type).to.eql 'aio:configure'
            expect(parsedMessage.dataType).to.eql 'aio:configure:set_env_variables'
            expect(parsedMessage.data).to.eql {'env1': '123', 'env2': '234'}
            done()

          request(app)
            .put('/boxes/mclovin')
            .auth('aio', 'foobar')
            .send('box': {'boxer_id':'boxer-id', 'data_type': 'aio:configure:set_env_variables', 'data': {'env1': '123', 'env2': '234'}})
            .expect(202)
            .end (err, res) ->
              resultObject = JSON.parse(res.text)
              expect(resultObject.status).to.eql "OK"

    context 'removing env variables', ->
      it 'responds with 202', (done) ->
        boxer.subscribe settings.boxerChannel, (err, result) ->
          return done(err) if err
          boxer.on 'message', (channel, rawMessage) ->
            parsedMessage = JSON.parse(rawMessage)
            expect(parsedMessage.name).to.eql 'mclovin'
            expect(parsedMessage.id).to.eql 'boxer-id'
            expect(parsedMessage.type).to.eql 'aio:configure'
            expect(parsedMessage.dataType).to.eql 'aio:configure:remove_env_variables'
            expect(parsedMessage.data).to.eql ['env1', 'env2']
            done()

          request(app)
            .put('/boxes/mclovin')
            .auth('aio', 'foobar')
            .send('box': {'boxer_id':'boxer-id', 'data_type': 'aio:configure:remove_env_variables', 'data': ['env1', 'env2']})
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
            expect(parsedMessage.type).to.eql 'aio:stop'

            done()

          request(app)
            .put('/boxes/mclovin/stop')
            .auth('aio', 'foobar')
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
            expect(parsedMessage.type).to.eql 'aio:destroy'

            done()

          request(app)
            .put('/boxes/mclovin/destroy')
            .auth('aio', 'foobar')
            .send('box': {'boxer_id':'boxer-id'})
            .expect(202)
            .end (err, res) ->
              resultObject = JSON.parse(res.text)
              expect(resultObject.status).to.eql "OK"

