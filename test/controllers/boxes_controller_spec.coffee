MessageParser = require '../../app/lib/message_parser'
initRedisClientWith = require('../../app/lib/utils').initRedisClientWith
boxerListener = require('../../app').boxerListener

assertCode = (res, code) ->
  expect(res.statusCode).to.eql code

assertStatus = (res, status) ->
  resultObject = JSON.parse(res.text)
  expect(resultObject.status).to.eql status

describe 'BoxesController', ->
  boxer = settings = null

  # utility to help send request to the app
  makeRequest = (method, path) -> request(app)[method](path).auth('aio', 'foobar')
  get = (path, data) -> makeRequest('get', path).send(data)
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
        post('/boxes', {'box': {'name':'mclovin','id':'1','runtime':'ruby','memory':'256','disk_space':'2048', 'user_name': 'foo', 'user_email': 'foo@example.com'}})
          .end (err, res) ->
            assertStatus res, "MISSING"
            assertCode res, 404
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
          expect(parsedMessage.userName).to.eql 'foo'
          expect(parsedMessage.userEmail).to.eql 'foo@example.com'
          expect(parsedMessage.type).to.eql 'aio:create'
          expect(parsedMessage.id).to.eql 'boxer-id'
          expect(parsedMessage.publicKeys).to.eql ['public-key-1','public-key-2']
          done()

        subscribeAndDo ->
          boxer.on 'message', assertMessage
          post('/boxes', {'box': {
            'name':'mclovin',
            'id':'1',
            'runtime':'ruby',
            'memory':'256',
            'disk_space':'2048',
            'user_name':'foo',
            'user_email':'foo@example.com',
            'public_keys':'["public-key-1","public-key-2"]',''}})
            .end (err, res) ->
              assertStatus res, "OK"
              assertCode res, 202

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
          expect(parsedMessage.userName).to.eql 'foo'
          expect(parsedMessage.userEmail).to.eql 'foo@example.com'
          expect(parsedMessage.type).to.eql 'aio:create'
          expect(parsedMessage.id).to.eql 'boxer-id'
          expect(parsedMessage.publicKeys).to.be.undefined
          done()

        subscribeAndDo ->
          boxer.on 'message', assertMessage
          post('/boxes', {'box': {'name':'mclovin','id':'1','runtime':'ruby','memory':'256','disk_space':'2048','user_name':'foo','user_email':'foo@example.com','public_keys':'abc'}})
            .end (err, res) ->
              assertStatus res, "OK"
              assertCode res, 202

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
          .end (err, res) ->
            assertStatus res, "OK"
            assertCode res, 202

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
            .end (err, res) ->
              assertStatus res, "OK"
              assertCode res, 202

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
            .end (err, res) ->
              assertStatus res, "OK"
              assertCode res, 202

    context 'setting env variables', ->
      it 'responds with 202', (done) ->
        assertMessage = (channel, rawMessage) ->
          parsedMessage = JSON.parse(rawMessage)
          expect(parsedMessage.name).to.eql 'mclovin'
          expect(parsedMessage.id).to.eql 'boxer-id'
          expect(parsedMessage.type).to.eql 'aio:configure'
          expect(parsedMessage.dataType).to.eql 'aio:configure:set_env_variables'
          expect(parsedMessage.data).to.eql {'env1': '123', 'env2': '234'}
          expect(parsedMessage.returnVars).to.eql {'addon_id':1}
          done()

        subscribeAndDo ->
          boxer.on 'message', assertMessage
          put('/boxes/mclovin', {'box': {
            'boxer_id':'boxer-id',
            'data_type': 'aio:configure:set_env_variables',
            'data': JSON.stringify({'env1': '123', 'env2': '234'})}, 'return_vars': JSON.stringify({'addon_id':1})})
            .end (err, res) ->
              assertStatus res, "OK"
              assertCode res, 202

    context 'removing env variables', ->
      it 'responds with 202', (done) ->
        assertMessage = (channel, rawMessage) ->
          parsedMessage = JSON.parse(rawMessage)
          expect(parsedMessage.name).to.eql 'mclovin'
          expect(parsedMessage.id).to.eql 'boxer-id'
          expect(parsedMessage.type).to.eql 'aio:configure'
          expect(parsedMessage.dataType).to.eql 'aio:configure:remove_env_variables'
          expect(parsedMessage.data).to.eql ['env1', 'env2']
          expect(parsedMessage.returnVars).to.eql {'addon_id':1}
          done()

        subscribeAndDo ->
          boxer.on 'message', assertMessage
          put('/boxes/mclovin', {'box': {
            'boxer_id':'boxer-id',
            'data_type': 'aio:configure:remove_env_variables',
            'data': JSON.stringify(['env1', 'env2'])}, 'return_vars': JSON.stringify({'addon_id':1})})
            .end (err, res) ->
              assertStatus res, "OK"
              assertCode res, 202

    context 'changing box specs', ->
      it 'responds with 202', (done) ->
        assertMessage = (channel, rawMessage) ->
          parsedMessage = JSON.parse(rawMessage)
          expect(parsedMessage.name).to.eql 'mclovin'
          expect(parsedMessage.id).to.eql 'boxer-id'
          expect(parsedMessage.type).to.eql 'aio:configure'
          expect(parsedMessage.dataType).to.eql 'aio:configure:change_specs'
          expect(parsedMessage.data).to.eql {'memory': '512M', 'diskSpace': '2G'}
          done()

        subscribeAndDo ->
          boxer.on 'message', assertMessage
          put('/boxes/mclovin', {
            'box': {
              'boxer_id':'boxer-id',
              'data_type': 'aio:configure:change_specs',
              'data': JSON.stringify({'memory': '512M', 'diskSpace': '2G'})
            },
            'return_vars': JSON.stringify({'addon_id':1})})
            .end (err, res) ->
              assertStatus res, "OK"
              assertCode res, 202

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
          .end (err, res) ->
            assertStatus res, "OK"
            assertCode res, 202

  describe 'PUT restart', ->
    beforeEach (done) ->
      boxer.subscribe settings.boxerChannel, (err, result) ->
        done() if !err

    it 'responds with 202', (done) ->
      assertMessage = (channel, rawMessage) ->
        parsedMessage = JSON.parse(rawMessage)
        expect(parsedMessage.name).to.eql 'mclovin'
        expect(parsedMessage.id).to.eql 'boxer-id'
        expect(parsedMessage.type).to.eql 'aio:restart'
        done()

      subscribeAndDo ->
        boxer.on 'message', assertMessage
        put('/boxes/mclovin/restart', {'box': {'boxer_id':'boxer-id'}})
          .end (err, res) ->
            assertStatus res, "OK"
            assertCode res, 202

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
          .end (err, res) ->
            assertStatus res, "OK"
            assertCode res, 202

  describe 'GET show', ->
    beforeEach (done) ->
      boxer.subscribe settings.boxerChannel, (err, result) ->
        done() if !err

    it 'responds with 202', (done) ->
      assertMessage = (channel, rawMessage) ->
        parsedMessage = JSON.parse(rawMessage)
        expect(parsedMessage.name).to.eql 'mclovin'
        expect(parsedMessage.id).to.eql 'boxer-id'
        expect(parsedMessage.type).to.eql 'aio:info_request'
        done()

      subscribeAndDo ->
        boxer.on 'message', assertMessage

        get('/boxes/mclovin', {'box': {'boxer_id':'boxer-id'}})
          .end (err, res) ->
            assertStatus res, "OK"
            assertCode res, 202
