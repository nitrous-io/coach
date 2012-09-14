ActionWebhook = require '../../app/lib/action_webhook'
StartedMessage = require '../../app/protocol/started_message'
express = require 'express'


describe 'ActionWebhook', ->
  describe '.sendNotification', ->
    message = app = null

    beforeEach ->
      message = new StartedMessage
                                  id: 'boxer-id'
                                  boxId: 1
                                  hostName: 'mclovin'

      app = express()
      app.configure ->
        app.use express.bodyParser()

      app.put '/boxes/1/webhook', (req, res) ->
        payload = JSON.parse(req.body.payload)
        payload['X-SECRET'] = req.get('X-SECRET')
        res.send(payload)

      app.listen(3306)

    afterEach ->
      app = null

    it 'should send a request to the webhook URL', (done) ->
      ActionWebhook.sendNotification message, (err, res) ->
        expect(res.body['X-SECRET']).to.eql 'foobar'
        expect(res.body['id']).to.eql 'boxer-id'
        expect(res.body['boxId']).to.eql 1
        expect(res.body['hostName']).to.eql 'mclovin'
        expect(res.body['type']).to.eql 'aio.started'
        done()


