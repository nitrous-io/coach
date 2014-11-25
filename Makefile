test:
	NODE_ENV=test node_modules/.bin/mocha $(MOCHA_OPTS) test/**/*_spec.*
.PHONY: test

image: 
	@docker build -t nitrousio/coach .
.PHONY: image

ci-test: image
	@docker run nitrousio/coach /home/app_runner/coach/script/docker_test
.PHONY: ci-test
