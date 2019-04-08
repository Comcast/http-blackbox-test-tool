VERSION?=2.0.0
IMAGE_NAME=http-blackbox-test-tool
IMAGE_PATH=${IMAGE_NAME}:${VERSION}
FULL_IMAGE_PATH=${REGISTRY}/${IMAGE_NAME}:${VERSION}

.PHONY: build push build-and-push test run

shell:
	docker run --privileged=true -v /var/run/docker.sock:/var/run/docker.sock -it ${IMAGE_NAME}:${VERSION} /bin/bash

build: guard-REGISTRY
	docker build -t ${IMAGE_NAME} .
	docker tag ${IMAGE_NAME} ${REGISTRY}/${IMAGE_NAME}:${VERSION}

push: guard-REGISTRY
	docker push ${REGISTRY}/${IMAGE_NAME}:${VERSION}

test:
	ruby test/http-blackbox-unit-tests.rb

run:
	ruby docker_http_test.rb

build-and-push: build push


guard-%:
	@ if [ "${${*}}" = "" ]; then \
		echo "Environment variable [$*] not set"; \
		exit 1; \
	fi