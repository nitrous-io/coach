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

    afterEach ->
      app = null

    context 'when the web server throws errors', ->
      currentAttempt = 0

      beforeEach ->
        app.listen(3306)
        app.put '/boxes/1/webhook', (req, res) ->
          payload = JSON.parse(req.body.payload)
          if currentAttempt == 0
            res.send(502, payload)
          else if currentAttempt == 1
            setTimeout ->
              res.send(200, payload)
              3*1000
          else
            res.send(200, payload)
          currentAttempt++

      afterEach ->
        currentAttempt = 0

      it 'should send a request to the webhook URL and retry', (done) ->
        @timeout(0)
        ActionWebhook.sendNotification message, (err, res) ->
          expect(res.status).to.eql 200
          expect(res.body['id']).to.eql 'boxer-id'
          expect(res.body['boxId']).to.eql 1
          expect(res.body['name']).to.eql 'mclovin'
          expect(res.body['type']).to.eql 'aio:started'
          expect(currentAttempt).to.eql 2
          done()


