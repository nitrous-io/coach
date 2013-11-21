test:
	NODE_ENV=test node_modules/.bin/mocha $(MOCHA_OPTS) test/**/*_spec.*

.PHONY: test
