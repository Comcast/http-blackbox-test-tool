# HTTP Blackbox Test tool
[![Apache V2 License](http://img.shields.io/badge/license-Apache%20V2-blue.svg)](https://github.com/Comcast/caduceus/blob/master/LICENSE)


## Purpose

  HTTP Blackbox Test Tool is intended to be a simple, declarative HTTP testing tool.
  
  * declarative test plan is written in yaml
  * to perform http [blackbox](http://softwaretestingfundamentals.com/black-box-testing/) tests against any external http resources.
  * first class support for Docker testing (WIP/future)
  * ability to run in CI (WIP/future) (doc)
  * first class support for Kubernetes testing (future)
  * portability/ease of sharing configurations (future) 
  
## Features

### requests
  * retries (useful for waiting for an HTTP resource to start-up/healthchecks)
  * send specified HTTP headers
  * all HTTP verbs supported
  * send payload from text file
  * ability to specify request counts (execute same request X times)
   
### responses
  * validate status codes
  * validate against file text
  * validate HTTP headers
  * validate via regular expressions
  * validate via XPath
  * validate against text files (exact match)
  * validate XML using XML equivalence, not text equivalence.  e.g. whitespace not significant, attribute ordering not significant
  * ability to ignore XML attributes and/or elements
  
### roadmap
  * ability to read environment variables
  * JSON/JSON Path
  * variable extraction (???)
  * Xpath/Regex combination 
  * Dynamic date/time
  * Date/time validation
  
### configuration

http-blackbox-test-tool is configured via a `test-plan.yaml` file.

The test-plan is a set of steps, each with an HTTP request and response definition.

**NOTE: the steps are executed in order as defiined in the file**\
**NOTE: the order of of attributes in the request/request configuration does NOT matter**

a `test-plan.yaml` file has the following structure:
* ${human readable/descriptive step name}
    * request (definition of an http request)
        * url
        * method - HTTP method
        * type (optional) (`xml`, `json`, `text`)
        * headers (optional) - HTTP Headers
            * `${header-name}` : `${header-value}'
        * filePath (optional, path to payload file)
        * count (optional) - number of times to execute request 
        * debug (optional) (true/false) - output the request text 

    * expectedResponse (definiton of expected HTTP reponse)
        * statusCode - expected HTTP status code
        * filePath (optional, path to payload file to match)
        * type (optional) (`xml`, `json`, `text`)
        * headers (optional) - HTTP Headers
            * `${header-name}` : `${header-value}'
        * filePath (optional, path to payload file)
        * xpath (xpath expressions to match)
            * `${xpath expression}` : `${value}`
        * ignoreElements (optional) - array of XML elements to ignore (valid ony if request type is `xml`)
        * ignoreAttributes (optional) - array of XML attributes to ignore (valid ony if request type is `xml`)
        * regex (regular expressions to match)
            *  `${regular expression`: `${value} ` (value can either be a string containing the match or a true/false boolean for a match/no match)
        * debug (optional) (true/false) - output the response text 
    

#### Example test plan (yaml file)

```yaml
# --- health checks (wait for service to start) ---
order-lunch-app-health:
  request:
    url: http://order-app:8080/health
    headers: 
      content-type: 'application/text'
    method: get
  expectedResponse:
    statusCode: 200
    maxRetryCount: 5

# --- send order from order. ---
post-order:
  request:
    url: http://order-app:8080/create
    method: post
    headers: 
      content-type: 'text/xml'
    type: xml
    filePath: ~/dev/tests/my-hamburger-order.xml
  expectedResponse:
    type: xml
    headers: 
      content-type: 'text/xml'
    statusCode: 201
    ignoreElements: ['createTime', 'orderId']
    filePath: ~/dev/tests/hamburger-order-acknowlege.xml

validate-hamburger-order-metrics:
  request:
    url: http://order-app:8080/metrics
    method: get
    type: text
    regex: 
      'order{product="burger"} (\d)': 1

blast-order:
  request:
    count: 20
    url: http://order-app:8080/create
    method: post
    type: xml
    filePath: ~/dev/tests/my-chicken-order.xml
  expectedResponse:
    type: xml
    statusCode: 201
    ignoreAttributes: ['createTime', 'orderId']
    filePath: ~/dev/tests/chicken-order-acknowlege.xml

validate-blast-order-metrics:
  request:
    headers: 
      'content-type: 'text'
    url: http://order-app:8080/metrics
    method: get
  expectedResponse:
    headers: 
      'content-type: 'text'
    regex: 
      'order_count{product="burger"} (\d)': 1
      'order_count{product="chicken"} (\d)': 20
      'order_total_count (\d)': 21
```

### docker

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


## Build/Test Instructions:

build - `make build`

push to docker registry - `make push`

test = `make test'


## Local Dev Setup:

```
install ruby
install bundler
bundle install
```


## TODO - NEED HELP!
* Needs to better support plain text
* JSON
* inline text for payloads
* XML support needs to be expanded:
  * xpath for attribute/element validation for both literal strings and regex
* Header support expanded:
  * validate headers by regex
* Kubernetes
    * watch logs for pattern (how?)
    * deploy http bb to remote k8s along with services?


