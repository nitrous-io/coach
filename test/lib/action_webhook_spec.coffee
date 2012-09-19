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
                                  name: 'mclovin'

      app = express()
      app.configure ->
        app.use express.bodyParser()
        app.use express.basicAuth  (user, pass) ->
          user == 'aio' && pass == 'foobar'

      app.put '/boxes/1/webhook', (req, res) ->
        payload = JSON.parse(req.body.payload)
        res.send(payload)

      app.listen(3306)

    afterEach ->
      app = null

    it 'should send a request to the webhook URL', (done) ->
      ActionWebhook.sendNotification message, (err, res) ->
        expect(res.body['id']).to.eql 'boxer-id'
        expect(res.body['boxId']).to.eql 1
        expect(res.body['name']).to.eql 'mclovin'
        expect(res.body['type']).to.eql 'aio:started'
        done()


