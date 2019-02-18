ifndef REGISTRY
$(error REGISTRY is not set)
endif

VERSION?=latest
IMAGE_NAME=http-blackbox-test-tool
IMAGE_PATH=${IMAGE_NAME}:${VERSION}
FULL_IMAGE_PATH=${REGISTRY}/${IMAGE_NAME}:${VERSION}

.PHONY: build push build-and-push test run

shell:
	docker run --privileged=true -v /var/run/docker.sock:/var/run/docker.sock -it ${IMAGE_NAME}:${VERSION} /bin/bash

build:
	docker build -t ${IMAGE_NAME} .
	docker tag ${IMAGE_NAME} ${REGISTRY}/${IMAGE_NAME}:${VERSION}

push:
	docker push ${REGISTRY}/${IMAGE_NAME}:${VERSION}

test:
	ruby test/http-blackbox-unit-tests.rb

run:
	ruby docker_http_test.rb

build-and-push: build push
