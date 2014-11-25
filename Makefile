test:
	NODE_ENV=test node_modules/.bin/mocha $(MOCHA_OPTS) test/**/*_spec.*
.PHONY: test

image: 
	@docker build -t nitrousio/coach .
.PHONY: image

ci-test: image
	@./script/ci
.PHONY: ci-test
