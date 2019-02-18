# HTTP Blackboxer
[![Apache V2 License](http://img.shields.io/badge/license-Apache%20V2-blue.svg)](https://github.com/Comcast/caduceus/blob/master/LICENSE)


## Purpose

  HTTP Blackboxer is intended to perform http [blackbox](http://softwaretestingfundamentals.com/black-box-testing/) tests against a docker container.

  [Docker](https://docker.com) is a technology used to run linux instances aka `containers` in a pre-defined state with all dependencies baked in.  Docker `Images` are the executable binary that are executed via a Docker Runtime that must be installed on the target machine.  `Containers` are the runtime instance.

  In a containerized world, there are new challenges to testing applications.

  Unit tests do not provide visibility into whether a docker container starts properly.

  Fully deployed, orchestrated application testing is applied too late in the development cycle usually after code has been checked in, merged to master, and gone through a deployment cycle.  Often end-to-end testing find problems hours or days after a code check-in.

  A developer wants to detect problems in the code as soon as possible.  The cost of fixing bugs goes up exponentially the later in the development cycle that it is detected:  https://www.synopsys.com/blogs/software-security/cost-to-fix-bugs-during-each-sdlc-phase/
  https://link.springer.com/article/10.1007/BF00402646

  Ideally the developer can detect the bug while they are writing the code and before the code is checked in.  The developer understands the changes they are making at that point in time.

  This project was created to facilitate using HTTP requests and responses to test docker containerized applications both individually and wired to other containers.  This project is not currently intended to test out deployment to complex environments.

## Goals
  * Simple HTTP Testing for Docker Containers (e.g. [smoke tests](https://en.wikipedia.org/wiki/Smoke_testing_(software))
  * test an individual docker image using HTTP
  * test docker container wired to other docker containers
  * simple declarative configuration

## Example Use Cases
  * does the built docker image start up and response to an HTTP health-check?
  * does an HTTP Get/Post to the a running docker image behave as expected?
  * does image behave properly when wired to other docker containers?
  * does an HTTP Post make it through the target container to a second wired container?
  * does applied docker image configuration behave as expected?


## Build Instructions:

build - `make build`


push to docker registry - `make push`


## Local Dev Setup:

```
install ruby
install bundler
bundle install
```

## Usage

`docker run -v ${LOCAL_TEST_DIR}:/${TARGET_TEST_DIR}  -e TEST_DIR=/smoke-test viper-ace/docker-http-test:latest`

e.g.
`docker run -v ${PWD}/test:/smoke-test  -e TEST_DIR=/smoke-test viper-ace/docker-http-test:latest`

`TEST_DIR` must contain any payload files and a test-plan.yaml file

A `test.yaml` file contains the test plan to execute.

The format is:
```yaml
$test-name:
  url: $url-to-test (required)
  httpMethod: ${get|post} (required)
  expectedHttpStatusCode: ${expectedCode} (required)
  maxRetryCount: ${max retry count with 1 second delay} (optional, defaults to 1)
  payloadPath: ${file path to payload to send with request in docker conatiner} (optional)
  expectedReponsePath: ${file path to response to send with request in docker conatiner} (optional)
```

Sample test-play.yaml file:

```yaml
smoke-health:
  url: http://myapp:8080/health
  httpMethod: get
  expectedHttpStatusCode: 200
  maxRetryCount: 10

smoke-post-psn:
  url: http://myapp:8080/psn
  httpMethod: post
  expectedHttpStatusCode: 200
  payloadPath: test/psn_base64encoded.xml
  expectedResponsePath: test/expected_psn_proxy_response.xml
```

sample test run:

```
$> docker run -v ${PWD}/test:/smoke-test  -e TEST_DIR=/smoke-test viper-ace/http-blackboxer:latest

*** TEST_DIR =test (test-plan.yaml + supporting test files expected in this directory) ***
{"smoke-health"=>{"url"=>"http://myapp:8080/health", "httpMethod"=>"get", "expectedHttpStatusCode"=>200, "maxRetryCount"=>10}, "smoke-post-psn"=>{"url"=>"http://myapp:8080/psn", "httpMethod"=>"post", "expectedHttpStatusCode"=>200, "payloadPath"=>"test/psn_base64encoded.xml", "expectedResponsePath"=>"test/expected_psn_proxy_response.xml"}}
-------------------------Executing test [smoke-health]--------------------------
Sending Http get to http://myapp:8080/health...
http check:[http://myapp:8080/health]
Expected status code [200] verified.
Success!
------------------------Executing test [smoke-post-psn]-------------------------
Sending Http post to http://myapp:8080/psn...
Expected status code [200] verified.
Actual response matches expected response
Success!
----------------------------Test Execution Success!-----------------------------
```

## Leveraging Docker Compose for Integration Testing

Running docker directly is fairly straight-forward for testing one Docker image/container at a time.

For testing integration of multiple docker containers wired together it can get much more complicated very quickly.

[Docker Compose](https://docs.docker.com/compose/overview/) is the recommended way to execute http-blackboxer against a locally built docker image and wiring the new image against other docker images.

Docker Compose is packaged with Docker for Mac/Windows.  For linux it must be [installed](https://docs.docker.com/compose/install/) separately.  It is *highly* recommended to use the latest version of docker-compose and docker.  Improvements have been made recently to better deal with concurrent use of docker-compose (important in a CI environment).

A `docker-compose.yaml` file provides instructions on which images to start, dependencies between the containers, environment variables to pass in, and files/volumes to share.  Full documentation on how to write a docker-compose file is [here](https://docs.docker.com/compose/compose-file/).

## Detailed Docker Compose Example

A docker-compose file for http-blackboxer looks something like:

```yaml
version: '3'
services:
  psn-sink:
    container_name: "psn-sink"
    image: registry.vipertv.net/viper-ace/psn-sink:1.2.0
  psnproxy:
    container_name: "psnproxy"
    image: "${IMAGE}"
    depends_on:
      - psn-sink
    environment:
      - ENDPOINT=http://psn-sink:8000/sink
  smoke:
    container_name: "smoke"
    image: registry.vipertv.net/viper-ace/http-blackboxer:latest
    depends_on:
      - psnproxy
    volumes:
       - .:/smoke-test
    environment:
      - TEST_DIR=/smoke-test
      - DEBUG=true
```

Explanation:
  `services` list all the docker containers to execute.
  `image` specifies the docker image to execute for a service.
  `depends_on` specifies a dependency on a container (e.g. don't start container X until container Y is running).  Not that a running container does *NOT* mean that it is fully started!
  `environment` specifies environment variables to pass into the container
  `volumes` specify local disk to share to a container.  For http-blackbox this is where you share your test plan and supporting files.

For the above configuration the `TEST_DIR` environment variable is setup to point to the http blackbox container's `/smoke-test` directory.  Any directory can be mapped, but the `TEST_DIR` environment variable must be specified so the http-blackboxer container knows where the test files are located.


The corresponding `TEST_DIR` files are:

```
docker-compose.yaml
expected-psn-sink-response.xml
expected_psn_proxy_response.xml
psn.xml
psn_base64encoded.xml
test-plan.yaml
```

The `test-plan.yaml` file looks like:

```yaml
smoke-health-psn-proxy:
  url: http://psnproxy:8080/health
  httpMethod: get
  expectedHttpStatusCode: 200
  maxRetryCount: 10

smoke-health-psn-sink:
  url: http://psn-sink:8000/lastRequest
  httpMethod: get
  expectedHttpStatusCode: 200
  maxRetryCount: 10

smoke-post-psn:
  url: http://psnproxy:8080/psn
  httpMethod: post
  expectedHttpStatusCode: 200
  payloadPath: /smoke-test/psn_base64encoded.xml
  expectedResponsePath: /smoke-test/expected_psn_proxy_response.xml

# validate psn-sink depends on post-psn to create expected state
smoke-validate-psn-sink:
  url: http://psn-sink:8000/lastRequest
  httpMethod: get
  expectedHttpStatusCode: 200
  expectedResponsePath: /smoke-test/expected-psn-sink-response.xml
```

Explanation:
  * the `smoke-health` cases describe calling a GET against a URL endpoint.  The try up to 10 times (1 second delay between retries) for an HTTP 200 response.
  * the `smoke-post-psn` call posts a specified XML payload to the endpoint and specifies an XML file that should match the response.
  * the `smoke-validate-psn-sink` case checks a docker container 'psn-sink` that was wired to the `psn-proxy` container to see if the payload made it there and matches expectations (specified in the `expectedResponsePath`)

## Running Docker Compose in CI

Docker Compose





## TODO - NEED HELP!
* test coverage!
* current implementation is XML-centric.  Needs to better support plain text and have full support for JSON
* XML support needs to be expanded:
  * xpath for attribute/elemnt validataion for both literal strings and regex
  * configurable XML attributes to ignore
  * configurable XML elements to ignore
* Configuration for HTTP Headers
  * HTTP headers to send
  * validate responses have HTTP Headers (exist and/or match)
* build CI tooling to run in hosted CI + publish to docker registry
* modify docker build so image is much smaller (currently > 500meg, way too big)
