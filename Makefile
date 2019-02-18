OWNER=linen
REGISTRY=hub.comcast.com
VERSION?=latest
IMAGE_NAME=http-blackbox-test-tool
IMAGE_PATH=${OWNER}/${IMAGE_NAME}:${VERSION}
FULL_IMAGE_PATH=${REGISTRY}/${OWNER}/${IMAGE_NAME}:${VERSION}

.PHONY: build push build-and-push test run

shell:
	docker run --privileged=true -v /var/run/docker.sock:/var/run/docker.sock -it ${OWNER}/${IMAGE_NAME}:${VERSION} /bin/bash

build:
	docker build -t ${OWNER}/${IMAGE_NAME} .
	docker tag ${OWNER}/${IMAGE_NAME} ${REGISTRY}/${OWNER}/${IMAGE_NAME}:${VERSION}

push:
	docker push ${REGISTRY}/${OWNER}/${IMAGE_NAME}:${VERSION}

test:
	ruby test/http-blackbox-unit-tests.rb

run:
	ruby docker_http_test.rb

build-and-push: build push
