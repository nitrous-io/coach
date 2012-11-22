MessageParser = require '../../app/lib/message_parser'
initRedisClientWith = require('../../app/lib/utils').initRedisClientWith
boxerListener = require('../../app').boxerListener

assertStatus = (res, status) ->
  resultObject = JSON.parse(res.text)
  expect(resultObject.status).to.eql status

describe 'BoxesController', ->
  boxer = settings = null

  # utility to help send request to the app
  makeRequest = (method, path) -> request(app)[method](path).auth('aio', 'foobar')
  get = (path) -> makeRequest('get', path)
  put = (path, data) -> makeRequest('put', path).send(data)
  post = (path, data) -> makeRequest('post', path).send(data)
  del = (path) -> makeRequest('delete', path)

  # subscribe boxer and perform action after subscribe
  subscribeAndDo = (cb) ->
    boxer.subscribe settings.boxerChannel, (err, result) ->
      return done(err) if err
      cb()

  beforeEach ->
    settings = require '../../config/settings'
    boxer = initRedisClientWith(settings.redisMQ)

  afterEach ->
    boxer.unsubscribe()
    boxer = null

  describe 'POST create', ->
    context 'boxer is not present', ->
      beforeEach ->
        sinon.stub(boxerListener, 'chooseBoxer').returns null

      afterEach ->
        boxerListener.chooseBoxer.restore()

      it 'responds with 404', (done) ->
        post('/boxes', {'box': {'name':'mclovin','id':'1','runtime':'ruby','memory':'256','disk_space':'2048'}})
          .expect(404)
          .end (err, res) ->
            assertStatus res, "MISSING"
            done()

    context 'boxer is present (valid params)', ->
      beforeEach ->
        sinon.stub(boxerListener, 'chooseBoxer').returns id: 'boxer-id'

      afterEach ->
        boxerListener.chooseBoxer.restore()

      it 'responds with 202', (done) ->
        assertMessage = (channel, rawMessage) ->
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

        subscribeAndDo ->
          boxer.on 'message', assertMessage
          post('/boxes', {'box': {
            'name':'mclovin',
            'id':'1',
            'runtime':'ruby',
            'memory':'256',
            'disk_space':'2048',
            'ssh_key_pair':"{\"public_key\":\"public-key\",\"private_key\":\"private-key\"}",
            'public_keys':'["public-key-1","public-key-2"]',''}})
            .expect(202)
            .end (err, res) -> assertStatus res, "OK"

    context 'boxer is present (invalid params)', ->
      beforeEach ->
        sinon.stub(boxerListener, 'chooseBoxer').returns id: 'boxer-id'

      afterEach ->
        boxerListener.chooseBoxer.restore()

      it 'responds with 202', (done) ->
        assertMessage = (channel, rawMessage) ->
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

        subscribeAndDo ->
          boxer.on 'message', assertMessage
          post('/boxes', {'box': {'name':'mclovin','id':'1','runtime':'ruby','memory':'256','disk_space':'2048','public_keys':'abc'}})
            .expect(202)
            .end (err, res) ->
              assertStatus res, "OK"

  describe 'PUT start', ->
    beforeEach (done) ->
      boxer.subscribe settings.boxerChannel, (err, result) ->
        done() if !err

    it 'responds with 202', (done) ->
      assertMessage = (channel, rawMessage) ->
        parsedMessage = JSON.parse(rawMessage)
        expect(parsedMessage.name).to.eql 'mclovin'
        expect(parsedMessage.id).to.eql 'boxer-id'
        expect(parsedMessage.type).to.eql 'aio:start'
        done()

      subscribeAndDo ->
        boxer.on 'message', assertMessage
        put('/boxes/mclovin/start', {'box': {'boxer_id':'boxer-id'}})
          .expect(202)
          .end (err, res) -> assertStatus res, "OK"

  describe 'PUT update', ->
    beforeEach (done) ->
      boxer.subscribe settings.boxerChannel, (err, result) ->
        done() if !err

    context 'adding a public key', ->
      it 'responds with 202', (done) ->
        assertMessage = (channel, rawMessage) ->
          parsedMessage = JSON.parse(rawMessage)
          expect(parsedMessage.name).to.eql 'mclovin'
          expect(parsedMessage.id).to.eql 'boxer-id'
          expect(parsedMessage.type).to.eql 'aio:configure'
          expect(parsedMessage.dataType).to.eql 'aio:configure:add_public_key'
          expect(parsedMessage.data).to.eql 'public-key'
          done()

        subscribeAndDo ->
          boxer.on 'message', assertMessage

          put('/boxes/mclovin', {'box': {'boxer_id':'boxer-id', 'data_type': 'aio:configure:add_public_key', 'data': 'public-key'}})
            .expect(202)
            .end (err, res) -> assertStatus res, "OK"

    context 'removing a public key', ->
      it 'responds with 202', (done) ->
        assertMessage = (channel, rawMessage) ->
          parsedMessage = JSON.parse(rawMessage)
          expect(parsedMessage.name).to.eql 'mclovin'
          expect(parsedMessage.id).to.eql 'boxer-id'
          expect(parsedMessage.type).to.eql 'aio:configure'
          expect(parsedMessage.dataType).to.eql 'aio:configure:remove_public_key'
          expect(parsedMessage.data).to.eql 'public-key'
          done()

        subscribeAndDo ->
          boxer.on 'message', assertMessage
          put('/boxes/mclovin', {'box': {'boxer_id':'boxer-id', 'data_type': 'aio:configure:remove_public_key', 'data': 'public-key'}})
            .expect(202)
            .end (err, res) -> assertStatus res, "OK"

    context 'setting env variables', ->
      it 'responds with 202', (done) ->
        assertMessage = (channel, rawMessage) ->
          parsedMessage = JSON.parse(rawMessage)
          expect(parsedMessage.name).to.eql 'mclovin'
          expect(parsedMessage.id).to.eql 'boxer-id'
          expect(parsedMessage.type).to.eql 'aio:configure'
          expect(parsedMessage.dataType).to.eql 'aio:configure:set_env_variables'
          expect(parsedMessage.data).to.eql {'env1': '123', 'env2': '234'}
          done()

        subscribeAndDo ->
          boxer.on 'message', assertMessage
          put('/boxes/mclovin', {'box': {
            'boxer_id':'boxer-id',
            'data_type': 'aio:configure:set_env_variables',
            'data': JSON.stringify({'env1': '123', 'env2': '234'})}})
            .expect(202)
            .end (err, res) -> assertStatus res, "OK"

    context 'removing env variables', ->
      it 'responds with 202', (done) ->
        assertMessage = (channel, rawMessage) ->
          parsedMessage = JSON.parse(rawMessage)
          expect(parsedMessage.name).to.eql 'mclovin'
          expect(parsedMessage.id).to.eql 'boxer-id'
          expect(parsedMessage.type).to.eql 'aio:configure'
          expect(parsedMessage.dataType).to.eql 'aio:configure:remove_env_variables'
          expect(parsedMessage.data).to.eql ['env1', 'env2']
          done()

        subscribeAndDo ->
          boxer.on 'message', assertMessage
          put('/boxes/mclovin', {'box': {
            'boxer_id':'boxer-id',
            'data_type': 'aio:configure:remove_env_variables',
            'data': JSON.stringify(['env1', 'env2'])}})
            .expect(202)
            .end (err, res) -> assertStatus res, "OK"

  describe 'PUT stop', ->
    beforeEach (done) ->
      boxer.subscribe settings.boxerChannel, (err, result) ->
        done() if !err

    it 'responds with 202', (done) ->
      assertMessage = (channel, rawMessage) ->
        parsedMessage = JSON.parse(rawMessage)
        expect(parsedMessage.name).to.eql 'mclovin'
        expect(parsedMessage.id).to.eql 'boxer-id'
        expect(parsedMessage.type).to.eql 'aio:stop'
        done()

      subscribeAndDo ->
        boxer.on 'message', assertMessage
        put('/boxes/mclovin/stop', {'box': {'boxer_id':'boxer-id'}})
          .expect(202)
          .end (err, res) -> assertStatus res, "OK"

  describe 'PUT restart', ->
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
            expect(parsedMessage.type).to.eql 'aio:restart'
            done()

          request(app)
            .put('/boxes/mclovin/restart')
            .auth('aio', 'foobar')
            .send('box': {'boxer_id':'boxer-id'})
            .expect(202)
            .end (err, res) ->
              resultObject = JSON.parse(res.text)
              expect(resultObject.status).to.eql "OK"

  describe 'PUT destroy', ->
    beforeEach (done) ->
      boxer.subscribe settings.boxerChannel, (err, result) ->
        done() if !err

    it 'responds with 202', (done) ->
      assertMessage = (channel, rawMessage) ->
        parsedMessage = JSON.parse(rawMessage)
        expect(parsedMessage.name).to.eql 'mclovin'
        expect(parsedMessage.id).to.eql 'boxer-id'
        expect(parsedMessage.type).to.eql 'aio:destroy'
        done()

      subscribeAndDo ->
        boxer.on 'message', assertMessage

        put('/boxes/mclovin/destroy', {'box': {'boxer_id':'boxer-id'}})
          .expect(202)
          .end (err, res) -> assertStatus res, "OK"
