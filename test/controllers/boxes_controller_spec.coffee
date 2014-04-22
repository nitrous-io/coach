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
        post('/boxes', {'box': {'name':'mclovin','id':'1','runtime':'ruby','memory':'256','disk_space':'2048','virtual_memory':'256','cpu_shares':'512'}})
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
          expect(parsedMessage.boxId).to.eql 1
          expect(parsedMessage.runtime).to.eql 'ruby'
          expect(parsedMessage.snapshotId).to.eql 123
          expect(parsedMessage.snapshotUrl).to.eql 's3://buckets/snapshot-123.tar.gz'
          expect(parsedMessage.memory).to.eql '256'
          expect(parsedMessage.diskSpace).to.eql '2048'
          expect(parsedMessage.virtualMemory).to.eql '512'
          expect(parsedMessage.cpuShares).to.eql 1024
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
            'snapshot_id':'123',
            'snapshot_url':'s3://buckets/snapshot-123.tar.gz',
            'memory':'256',
            'disk_space':'2048',
            'virtual_memory':'512',
            'cpu_shares':'1024',
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
          expect(parsedMessage.boxId).to.eql 1
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
        expect(parsedMessage.data).to.eql {'memory': '1024M', 'diskSpace': '1000M', 'virtualMemory': '2048M', 'cpuShares': 512}
        done()

      subscribeAndDo ->
        boxer.on 'message', assertMessage
        put('/boxes/mclovin/start', {
          'box': {
            'boxer_id': 'boxer-id',
            'data': JSON.stringify({'memory': '1024M', 'diskSpace': '1000M', 'virtualMemory': '2048M', 'cpuShares': 512})
          }})
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

    context 'changing box specs', ->
      it 'responds with 202', (done) ->
        assertMessage = (channel, rawMessage) ->
          parsedMessage = JSON.parse(rawMessage)
          expect(parsedMessage.name).to.eql 'mclovin'
          expect(parsedMessage.id).to.eql 'boxer-id'
          expect(parsedMessage.type).to.eql 'aio:configure'
          expect(parsedMessage.dataType).to.eql 'aio:configure:change_specs'
          expect(parsedMessage.data).to.eql {'memory': '512M', 'diskSpace': '2G', 'virtualMemory': '512M'}
          done()

        subscribeAndDo ->
          boxer.on 'message', assertMessage

          put('/boxes/mclovin', {
            'box': {
              'boxer_id':'boxer-id',
              'data_type': 'aio:configure:change_specs',
              'data': JSON.stringify({'memory': '512M', 'diskSpace': '2G', 'virtualMemory': '512M'})
            },
            'return_vars': JSON.stringify({'addon_id':1})})
            .end (err, res) ->
              assertStatus res, "OK"
              assertCode res, 202

    context 'update auth', ->
      it 'responds with 202', (done) ->
        assertMessage = (channel, rawMessage) ->
          parsedMessage = JSON.parse(rawMessage)
          expect(parsedMessage.name).to.eql 'mclovin'
          expect(parsedMessage.id).to.eql 'boxer-id'
          expect(parsedMessage.type).to.eql 'aio:configure'
          expect(parsedMessage.dataType).to.eql 'aio:configure:update_auth'
          expect(parsedMessage.data).to.eql {'auth_username': 'admin', 'auth_password': 'password'}
          done()

        subscribeAndDo ->
          boxer.on 'message', assertMessage
          put('/boxes/mclovin', {'box': {
            'boxer_id':'boxer-id',
            'data_type': 'aio:configure:update_auth',
            'data': JSON.stringify({'auth_username': 'admin', 'auth_password': 'password'})}})
            .end (err, res) ->
              assertStatus res, "OK"
              assertCode res, 202

    context 'update premium flag', ->
      it 'responds with 202', (done) ->
        assertMessage = (channel, rawMessage) ->
          parsedMessage = JSON.parse(rawMessage)
          expect(parsedMessage.name).to.eql 'mclovin'
          expect(parsedMessage.id).to.eql 'boxer-id'
          expect(parsedMessage.type).to.eql 'aio:configure'
          expect(parsedMessage.dataType).to.eql 'aio:configure:update_premium'
          expect(parsedMessage.data).to.eql {'premium': true}
          done()

        subscribeAndDo ->
          boxer.on 'message', assertMessage
          put('/boxes/mclovin', {'box': {
            'boxer_id':'boxer-id',
            'data_type': 'aio:configure:update_premium',
            'data': JSON.stringify({'premium': true})}})
            .end (err, res) ->
              assertStatus res, "OK"
              assertCode res, 202

    context 'update custom domain', ->
      it 'responds with 202', (done) ->
        assertMessage = (channel, rawMessage) ->
          parsedMessage = JSON.parse(rawMessage)
          expect(parsedMessage.name).to.eql 'mclovin'
          expect(parsedMessage.id).to.eql 'boxer-id'
          expect(parsedMessage.type).to.eql 'aio:configure'
          expect(parsedMessage.dataType).to.eql 'aio:configure:update_custom_domain'
          expect(parsedMessage.data).to.eql {'custom_domain': 'wtf.com'}
          done()

        subscribeAndDo ->
          boxer.on 'message', assertMessage
          put('/boxes/mclovin', {'box': {
            'boxer_id':'boxer-id',
            'data_type': 'aio:configure:update_custom_domain',
            'data': JSON.stringify({'custom_domain': 'wtf.com'})}})
            .end (err, res) ->
              assertStatus res, "OK"
              assertCode res, 202

    context 'update sudo', ->
      it 'responds with 202', (done) ->
        assertMessage = (channel, rawMessage) ->
          parsedMessage = JSON.parse(rawMessage)
          expect(parsedMessage.name).to.eql 'mclovin'
          expect(parsedMessage.id).to.eql 'boxer-id'
          expect(parsedMessage.type).to.eql 'aio:configure'
          expect(parsedMessage.dataType).to.eql 'aio:configure:update_sudo'
          expect(parsedMessage.data).to.eql {'sudo': true}
          done()

        subscribeAndDo ->
          boxer.on 'message', assertMessage
          put('/boxes/mclovin', {'box': {
            'boxer_id':'boxer-id',
            'data_type': 'aio:configure:update_sudo',
            'data': JSON.stringify({'sudo': true})}})
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
        expect(parsedMessage.data).to.eql {'memory': '1024M', 'diskSpace': '1000M', 'virtualMemory': '2048M', 'cpuShares': 512}
        done()

      subscribeAndDo ->
        boxer.on 'message', assertMessage
        put('/boxes/mclovin/restart', {
          'box': {
            'boxer_id':'boxer-id',
            'data': JSON.stringify({'memory': '1024M', 'diskSpace': '1000M', 'virtualMemory': '2048M', 'cpuShares': 512})
          }})
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

  describe 'PUT snapshot', ->
    beforeEach (done) ->
      boxer.subscribe settings.boxerChannel, (err, result) ->
        done() if !err

    it 'responds with 202', (done) ->
      assertMessage = (channel, rawMessage) ->
        parsedMessage = JSON.parse(rawMessage)
        expect(parsedMessage.id).to.eql 'boxer-id'
        expect(parsedMessage.name).to.eql 'mclovin'
        expect(parsedMessage.snapshotId).to.eql 123
        expect(parsedMessage.type).to.eql 'aio:snapshot'
        done()

      subscribeAndDo ->
        boxer.on 'message', assertMessage

        put('/boxes/mclovin/snapshot', {
          'box': {
            'boxer_id': 'boxer-id',
            'snapshot_id': 123
          }
        }).end (err, res) ->
            assertStatus res, 'OK'
            assertCode res, 202

  describe 'PUT delete_snapshot', ->
    beforeEach (done) ->
      boxer.subscribe settings.boxerChannel, (err, result) ->
        done() if !err

    it 'responds with 202', (done) ->
      assertMessage = (channel, rawMessage) ->
        parsedMessage = JSON.parse(rawMessage)
        expect(parsedMessage.id).to.eql 'boxer-id'
        expect(parsedMessage.snapshotId).to.eql 123
        expect(parsedMessage.snapshotUrl).to.eql 's3://buckets/snapshot-123.tar.gz'
        expect(parsedMessage.type).to.eql 'aio:delete_snapshot'
        done()

      subscribeAndDo ->
        boxer.on 'message', assertMessage

        put('/snapshots/123/destroy', {
          'box': {
            'boxer_id': 'boxer-id'
          },
          'snapshot_url': 's3://buckets/snapshot-123.tar.gz'
        }).end (err, res) ->
            assertStatus res, 'OK'
            assertCode res, 202

  # this is only supported with goboxer now
  describe 'PUT migrate', ->
    it 'sends the migrate message to boxer', (done) ->
      assertMessage = (channel, rawMessage) ->
        parsedMessage = JSON.parse(rawMessage)
        expect(parsedMessage.name).to.eql 'mclovin'
        expect(parsedMessage.boxId).to.eql '1'
        expect(parsedMessage.type).to.eql 'aio:migrate'
        expect(parsedMessage.id).to.eql 'boxer-id'
        done()

      subscribeAndDo ->
        boxer.on 'message', assertMessage
        put('/boxes/mclovin/migrate', {'box': {
          'name':'mclovin',
          'id':'1',
          'boxer_id': 'boxer-id'}})
          .end (err, res) ->
            assertStatus res, "OK"
            assertCode res, 202

  describe 'PUT clone_repository', ->
    beforeEach (done) ->
      boxer.subscribe settings.boxerChannel, (err, result) ->
        done() if !err

    it 'responds with 202', (done) ->
      assertMessage = (channel, rawMessage) ->
        parsedMessage = JSON.parse(rawMessage)
        expect(parsedMessage.id).to.eql 'boxer-id'
        expect(parsedMessage.name).to.eql 'mclovin'
        expect(parsedMessage.repositoryUrl).to.eql 'https://github.com/nitrous-io/autoparts'
        expect(parsedMessage.repositoryScm).to.eql 'git'
        expect(parsedMessage.type).to.eql 'aio:clone_repository'
        done()

      subscribeAndDo ->
        boxer.on 'message', assertMessage

        put('/boxes/mclovin/clone_repo', {
          'box': {
            'boxer_id': 'boxer-id',
            'repository_url': 'https://github.com/nitrous-io/autoparts'
            'repository_scm': 'git'
          },
        }).end (err, res) ->
            assertStatus res, 'OK'
            assertCode res, 202
