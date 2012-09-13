process.env.NODE_ENV = 'test'

global.context = global.describe
global.xcontext = global.xdescribe
global.specify = global.it
global.xspecify = global.xit
global.its = global.it
global.xits = global.xit

global.sinon = require 'sinon'
global.chai = require 'chai'
global.should = global.chai.should()
global.expect = global.chai.expect
global.assert = global.chai.assert
sinonChai = require 'sinon-chai'
global.chai.use(sinonChai)

global.cleanDB = require './support/clean_db'

