# HTTP Blackbox test tool
[![Apache V2 License](http://img.shields.io/badge/license-Apache%20V2-blue.svg)](https://github.com/Comcast/caduceus/blob/master/LICENSE)


## Purpose

  HTTP Blackbox Test Tool is intended to perform http [blackbox](http://softwaretestingfundamentals.com/black-box-testing/) tests against a docker container.

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

## TODO - NEED HELP!
* test coverage!
* current implementation is XML-centric.  Needs to better support plain text and have full support for JSON
* XML support needs to be expanded:
  * xpath for attribute/element validation for both literal strings and regex
  * configurable XML attributes to ignore
  * configurable XML elements to ignore
* Configuration for HTTP Headers
  * HTTP headers to send
  * validate responses have HTTP Headers (exist and/or match)
* build CI tooling to run in hosted CI + publish to docker registry
* modify docker build so image is much smaller (currently > 500meg, way too big)
