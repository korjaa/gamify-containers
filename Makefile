.PHONY: default
default: build

.PHONY: build
build: Dockerfile.built

Dockerfile.built: Dockerfile entrypoint.sh pulse-client.conf
	docker build --tag gamify .
	@touch Dockerfile.built

.PHONY: debug
debug:
	docker run -it --rm --entrypoint=/bin/bash gamify

.PHONY: run
run: Dockerfile.built
	./play.sh /bin/bash -l
