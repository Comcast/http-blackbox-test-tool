require_relative "../http_blackbox_executer.rb"
require_relative "../validation_error"
require_relative "../execution_error"

require "test/unit"
require 'yaml'
require 'webmock/test_unit'

# read yaml test plan correctly
#

# split to test config
# test xml doc
# test json doc
#

class TestBlackbox < Test::Unit::TestCase
  def setup
    @test_plan_from_yaml = YAML.load_file("#{__dir__}/test-plan.yaml")
    @test_case_simple_get =
        {
            testCase:
                {
                    request: {
                        url: "http://sampleurl/health",
                        method: "get",
                    },
                    expectedResponse: {
                        type: "text",
                        maxRetryCount: 2,
                        statusCode: 200,
                    }
                }
        }

    @test_case_simple_get_with_header =
        {
            testCase:
                {
                    request: {
                        url: "http://sampleurl/psn",
                        method: "get",
                        headers: {
                            'content-type' => 'text/xml',
                            'test-header' => 'test-header-value',
                        },
                    },
                    expectedResponse: {
                        type: "text",
                        maxRetryCount: 1,
                        statusCode: 200,
                        headers: {
                            'content-type' => 'testpassed!',
                            'test-header2' => 'anoter-test-header-value',
                        },
                    }
                }
        }

    @test_case_post_request_no_response_payload =
        {
            testCase:
                {
                    request: {
                        url: "http://sampleurl/psn",
                        method: "post",
                        filePath: "#{__dir__}/psn.xml",
                        type: "text"
                    },
                    expectedResponse: {
                        maxRetryCount: 2,
                        statusCode: 201,
                    }
                }
        }

    @test_case_post_request_with_response_payload =
        {
            testCase:
                {
                    request: {
                        url: "http://sampleurl/psn",
                        method: "post",
                        filePath: "#{__dir__}/psn.xml",
                        type: "text"
                    },
                    expectedResponse: {
                        maxRetryCount: 2,
                        statusCode: 201,
                        filePath: "#{__dir__}/pass",
                        type: "text"
                    }
                }
        }

    @test_case_get_request_payload =
        {
            testCase:
                {
                    request: {
                        url: "http://sampleurl/psn",
                        filePath: "#{__dir__}/psn.xml",
                        method: "get",
                        type: "text"

                    },
                    expectedResponse: {
                        maxRetryCount: 2,
                        statusCode: 200,
                        filePath: "#{__dir__}/pass",
                        type: "text"
                    }
                }
        }

    @test_case_put_request_payload =
        {
            testCase:
                {
                    request: {
                        url: "http://sampleurl/psn",
                        filePath: "#{__dir__}/psn.xml",
                        method: "put",
                        type: "text"

                    },
                    expectedResponse: {
                        maxRetryCount: 2,
                        statusCode: 201,
                        filePath: "#{__dir__}/pass",
                        type: "text"
                    }
                }
        }


    @test_case_get_request_xml_response =
        {
            testCase:
                {
                    request: {
                        url: "http://sampleurl/psn",
                        method: "get"

                    },
                    expectedResponse: {
                        maxRetryCount: 2,
                        statusCode: 200,
                        filePath: "#{__dir__}/response.xml",
                        type: "xml"
                    }
                }
        }

    @test_case_get_request_xml_ignore_attr_response =
        {
            testCase:
                {
                    request: {
                        url: "http://sampleurl/psn",
                        method: "get"

                    },
                    expectedResponse: {
                        maxRetryCount: 2,
                        statusCode: 200,
                        filePath: "#{__dir__}/response.xml",
                        type: "xml",
                        ignoreAttributes: ['another-dummy-attribute']
                    }
                }
        }

    @test_case_get_request_xml_ignore_2_attr_response =
        {
            testCase:
                {
                    request: {
                        url: "http://sampleurl/psn",
                        method: "get"

                    },
                    expectedResponse: {
                        maxRetryCount: 2,
                        statusCode: 200,
                        filePath: "#{__dir__}/response.xml",
                        type: "xml",
                        ignoreAttributes: ['another-dummy-attribute', 'another-dummy-attribute-2']
                    }
                }
        }

    @test_case_get_request_xml_ignore_element_response =
        {
            testCase:
                {
                    request: {
                        url: "http://sampleurl/psn",
                        method: "get"

                    },
                    expectedResponse: {
                        maxRetryCount: 2,
                        statusCode: 200,
                        filePath: "#{__dir__}/response.xml",
                        type: "xml",
                        ignoreElements: ['nested-dummy2']
                    }
                }
        }

    @test_case_get_request_xml_ignore_elements_response =
        {
            testCase:
                {
                    request: {
                        url: "http://sampleurl/psn",
                        method: "get"

                    },
                    expectedResponse: {
                        maxRetryCount: 2,
                        statusCode: 200,
                        filePath: "#{__dir__}/response.xml",
                        type: "xml",
                        ignoreElements: ['nested-dummy2', 'dummy-with-attribute2']
                    }
                }
        }


    @test_case_request_xml_with_xpath =
        {
            testCase:
                {
                    request: {
                        url: "http://sampleurl/psn",
                        method: "get"

                    },
                    expectedResponse: {
                        maxRetryCount: 2,
                        statusCode: 200,
                        filePath: "#{__dir__}/response.xml",
                        ignoreElements: ['nested-dummy2', 'dummy-with-attribute2'],
                        type: "xml",
                        xpath: {"/dummy/dummy-with-attribute/@another-dummy-attribute": "another-value",
                                "/dummy/nested-dummy2/text()": "dummy-text"
                        },
                    }
                }
        }

    @test_case_request_text_with_regex =
        {
            testCase:
                {
                    request: {
                        url: "http://sampleurl/metrics",
                        method: "get"
                    },
                    expectedResponse: {
                        debug: true,
                        statusCode: 200,
                        type: "text",
                        regex: {'psnrouter_client_connection_error_count{.*} (\d)': "1",
                                'psnrouter_backend_request_duration_seconds_sum{product="PRODUCT!",reuse="false",site="PHIL!",url="localhost:7070/endpoint500"}': true,
                                'garbagethatdoesnotmatch': false,
                                'psnrouter_client_connection_error_count{.*} (\d)': 1  #make sure it works for both a string and an int on regex match
                        },
                    }
                }
        }

  end

  def test_get_with_xml_response_and_xpath
    name = @test_case_request_xml_with_xpath.keys.first
    test_config = @test_case_request_xml_with_xpath[name]
    test_case = HttpBlackboxExecuter.new(name, test_config)
    assert_not_nil test_case
    response_xml = IO.read("#{__dir__}/response.xml")
    stub_request(:get, "http://sampleurl/psn").to_return(lambda do |_|
      return {
          body: response_xml,
          status: 200
      }
    end)
    assert_nothing_raised do
      test_case.execute
    end
  end

  def test_get_with_xml_response_and_xpath_value_mismatch
    name = @test_case_request_xml_with_xpath.keys.first
    test_config = @test_case_request_xml_with_xpath[name]
    test_config[:expectedResponse][:xpath][:"/dummy/dummy-with-attribute/@another-dummy-attribute"] = "blah"
    test_case = HttpBlackboxExecuter.new(name, test_config)
    assert_not_nil test_case
    response_xml = IO.read("#{__dir__}/response.xml")
    stub_request(:get, "http://sampleurl/psn").to_return(lambda do |_|
      return {
          body: response_xml,
          status: 200
      }
    end)
    assert_raise do
      test_case.execute
    end
  end

  def test_get_max_retry
    name = @test_case_simple_get.keys.first
    test_config = @test_case_simple_get[name]
    test_case = HttpBlackboxExecuter.new(name, test_config)
    assert_not_nil test_case
    assert_raise do
      test_case.execute
    end
  end

  def test_health_bad_http_code
    name = @test_case_simple_get.keys.first
    test_config = @test_case_simple_get[name]
    test_case = HttpBlackboxExecuter.new(name, test_config)
    assert_not_nil test_case
    stub_request(:get, "http://sampleurl/health").to_return(status: 500)
    assert_raise do
      test_case.execute
    end
  end

  def test_simple_get_health
    name = @test_case_simple_get.keys.first
    test_config = @test_case_simple_get[name]
    test_case = HttpBlackboxExecuter.new(name, test_config)
    assert_not_nil test_case
    stub_request(:get, "http://sampleurl/health").to_return(status: 200)
    test_case.execute
  end

  def test_bogus_config
    name = @test_case_simple_get.keys.first
    test_config = @test_case_simple_get[name]
    test_config[:blah] = :blo
    assert_raise(ValidationError) do
      HttpBlackboxExecuter.new(name, test_config)
    end
  end

  def test_missing_config_request
    name = @test_case_simple_get.keys.first
    test_config = @test_case_simple_get[name]
    test_config.delete(:request)
    assert_raise(ValidationError) do
      HttpBlackboxExecuter.new(name, test_config)
    end
  end

  def test_missing_config_expected_response
    name = @test_case_simple_get.keys.first
    test_config = @test_case_simple_get[name]
    test_config = test_config.delete(:response)
    assert_raise do
      HttpBlackboxExecuter.new(name, test_config)
    end
  end

  def test_missing_config_request_url
    name = @test_case_simple_get.keys.first
    test_config = @test_case_simple_get[name]
    test_config[:request].delete(:url)
    assert_raise(ValidationError) do
      HttpBlackboxExecuter.new(name, test_config)
    end
  end

  def test_missing_config_request_method
    name = @test_case_simple_get.keys.first
    test_config = @test_case_simple_get[name]
    test_config[:request].delete(:method)
    assert_raise(ValidationError) do
      HttpBlackboxExecuter.new(name, test_config)
    end
  end

  def test_invalid_post_config
    name = @test_case_get_request_payload.keys.first
    test_config = @test_case_get_request_payload[name]
    test_config[:request].delete(:type)
    assert_raise(ValidationError) do
      HttpBlackboxExecuter.new(name, test_config)
    end
  end

  def test_invalid_response_config_type
    name = @test_case_get_request_payload.keys.first
    test_config = @test_case_get_request_payload[name]
    test_config[:expectedResponse].delete(:type)
    assert_raise(ValidationError) do
      HttpBlackboxExecuter.new(name, test_config)
    end

  end

  def test_get_with_payload
    name = @test_case_get_request_payload.keys.first
    test_config = @test_case_get_request_payload[name]
    test_case = HttpBlackboxExecuter.new(name, test_config)
    assert_not_nil test_case
    stub_request(:get, "http://sampleurl/psn").to_return(lambda do |request|
      result = (request.body.include? "1EA15585-1075-4833-86C6-9321695B5CE4") ? "pass" : "fail"
      return {
          body: result
      }
    end)
    assert_nothing_raised do
      test_case.execute
    end
    stub_request(:get, "http://sampleurl/psn").to_return(lambda do |request|
      result = (request.body.include? "text-that-will-not-match") ? "pass" : "fail"
      return {
          body: result
      }
    end)
    assert_raise(ExecutionError) do
      test_case.execute
    end
  end

  def test_all_methods_with_payload
    HttpBlackboxExecuter::HTTP_METHODS.each do |method|
      name = @test_case_put_request_payload.keys.first
      test_config = @test_case_get_request_payload[name]
      test_config[:request][:method] = method
      test_case = HttpBlackboxExecuter.new(name, test_config)
      assert_not_nil test_case
      stub_request(method.to_sym, "http://sampleurl/psn").to_return(lambda do |request|
        result = (request.body.include? "1EA15585-1075-4833-86C6-9321695B5CE4") ? "pass" : "fail"
        return {
            body: result
        }
      end)
      assert_nothing_raised do
        test_case.execute
      end
      stub_request(method.to_sym, "http://sampleurl/psn").to_return(lambda do |request|
        result = (request.body.include? "text-that-will-not-match") ? "pass" : "fail"
        return {
            body: result
        }
      end)
      assert_raise(ExecutionError) do
        test_case.execute
      end
    end
  end

  def test_post_with_request_payload
    name = @test_case_post_request_no_response_payload.keys.first
    test_config = @test_case_post_request_no_response_payload[name]
    test_case = HttpBlackboxExecuter.new(name, test_config)
    assert_not_nil test_case
    stub_request(:post, "http://sampleurl/psn").to_return(lambda do |_|
      return {
          status: 500
      }
    end)
    assert_raise(ExecutionError) do
      test_case.execute
    end

    stub_request(:post, "http://sampleurl/psn").to_return(lambda do |request|
      return {
          status: (request.body.include? "1EA15585-1075-4833-86C6-9321695B5CE4") ? 201 : 500
      }
    end)
    assert_nothing_raised do
      test_case.execute
    end

  end

  def test_post_with_request_and_response_payload
    name = @test_case_post_request_with_response_payload.keys.first
    test_config = @test_case_post_request_with_response_payload[name]
    test_case = HttpBlackboxExecuter.new(name, test_config)
    assert_not_nil test_case
    stub_request(:post, "http://sampleurl/psn").to_return(lambda do |request|
      result = (request.body.include? "1EA15585-1075-4833-86C6-9321695B5CE4") ? "pass" : "fail"
      return {
          body: result,
          status: 201
      }
    end)
    assert_nothing_raised do
      test_case.execute
    end

    stub_request(:post, "http://sampleurl/psn").to_return(lambda do |_|
      result = "fail"
      return {
          body: result,
          status: 201
      }
    end)
    assert_raise(ExecutionError) do
      test_case.execute
    end
  end


  def test_get_with_xml_response
    name = @test_case_get_request_xml_response.keys.first
    test_config = @test_case_get_request_xml_response[name]
    test_case = HttpBlackboxExecuter.new(name, test_config)
    assert_not_nil test_case
    response_xml = IO.read("#{__dir__}/response.xml")
    stub_request(:get, "http://sampleurl/psn").to_return(lambda do |_|
      return {
          body: response_xml,
          status: 200
      }
    end)
    assert_nothing_raised do
      test_case.execute
    end

    doc_with_nested_dummy_element_removed = get_xml_doc(response_xml)
    doc_with_nested_dummy_element_removed.xpath('//nested-dummy').each {|node| node.remove}

    stub_request(:get, "http://sampleurl/psn").to_return(lambda do |_|
      return {
          body: doc_with_nested_dummy_element_removed.to_s
      }
    end)
    assert_raise(ExecutionError) do
      test_case.execute
    end

    doc_with_nested_dummy_element_value_changed = get_xml_doc(response_xml)
    doc_with_nested_dummy_element_value_changed.xpath('//nested-dummy').first.content = "blah"
    stub_request(:get, "http://sampleurl/psn").to_return(lambda do |_|
      return {
          body: doc_with_nested_dummy_element_removed.to_s
      }
    end)
    assert_raise(ExecutionError) do
      test_case.execute
    end

    doc_with__attribute_changed = get_xml_doc(response_xml)
    doc_with__attribute_changed.xpath('/dummy/@dummy-attribute').first.content = "blah"
    stub_request(:get, "http://sampleurl/psn").to_return(lambda do |_|
      return {
          body: doc_with__attribute_changed.to_s
      }
    end)
    assert_raise(ExecutionError) do
      test_case.execute
    end

  end

  def test_get_with_xml_response_ignore_attr
    test_case = get_test_case_from_json(@test_case_get_request_xml_ignore_attr_response)
    response_xml = IO.read("#{__dir__}/response.xml")
    doc_with_attribute_changed = get_xml_doc(response_xml)
    doc_with_attribute_changed.xpath('/dummy/dummy-with-attribute/@another-dummy-attribute').first.content = "blah"

    stub_request(:get, "http://sampleurl/psn").to_return(lambda do |_|
      return {
          body: doc_with_attribute_changed.to_s,
          status: 200
      }
    end)
    assert_nothing_raised do
      test_case.execute
    end

    test_case_2_attr = get_test_case_from_json(@test_case_get_request_xml_ignore_2_attr_response)
    doc_with_attribute_changed.xpath('/dummy/dummy-with-attribute2/@another-dummy-attribute-2').first.content = "blah"
    stub_request(:get, "http://sampleurl/psn").to_return(lambda do |_|
      return {
          body: doc_with_attribute_changed.to_s,
          status: 200
      }
    end)
    assert_nothing_raised do
      test_case_2_attr.execute
    end

  end

  def test_get_with_xml_response_ignore_elements
    test_case = get_test_case_from_json(@test_case_get_request_xml_ignore_element_response)
    response_xml = IO.read("#{__dir__}/response.xml")
    doc_with_element_changed = get_xml_doc(response_xml)
    doc_with_element_changed.xpath('/dummy/nested-dummy2').first.content = "blah"

    stub_request(:get, "http://sampleurl/psn").to_return(lambda do |_|
      return {
          body: doc_with_element_changed.to_s,
          status: 200
      }
    end)
    assert_nothing_raised do
      test_case.execute
    end

    test_case_ignore_elements = get_test_case_from_json(@test_case_get_request_xml_ignore_elements_response)
    #change another element
    doc_with_element_changed.xpath('/dummy/dummy-with-attribute2').first.content = "blah"
    stub_request(:get, "http://sampleurl/psn").to_return(lambda do |_|
      return {
          body: doc_with_element_changed.to_s,
          status: 200
      }
    end)
    assert_nothing_raised do
      test_case_ignore_elements.execute
    end
  end

  def get_test_case_from_json(test_case_json)
    name = test_case_json.keys.first
    test_config = test_case_json[name]
    test_case = HttpBlackboxExecuter.new(name, test_config)
    assert_not_nil test_case
    return test_case
  end

  def test_get_headers
    test_case = get_test_case_from_json(@test_case_simple_get_with_header)
    response_xml = IO.read("#{__dir__}/response.xml")
    response_doc = get_xml_doc(response_xml)
    expected_headers_in_request = test_case.test_case_config['request']['headers']
    expected_headers_in_response = test_case.test_case_config['expectedResponse']['headers']

    stub_request(:get, "http://sampleurl/psn").to_return(lambda do |request|
      expected_headers_in_request.each do |header_key, header_value|
        observed_request_header_value = find_header_value_case_insensitve_key(header_key, request.headers)
        assert_not_nil observed_request_header_value
        assert header_value == observed_request_header_value
      end
      return {
          body: response_doc.to_s,
          headers: expected_headers_in_response,
          status: 200
      }
    end)
    assert_nothing_raised do
      test_case.execute
    end

    stub_request(:get, "http://sampleurl/psn").to_return(lambda do |_|
      return {
          body: response_doc.to_s,
          status: 200
      }
    end)

    assert_raise(ExecutionError) do
      test_case.execute
    end

    bad_expected_headers_in_response = {"content-type" => "blah"}

    stub_request(:get, "http://sampleurl/psn").to_return(lambda do |_|
      return {
          body: response_doc.to_s,
          status: 200,
          headers: bad_expected_headers_in_response
      }
    end)
    assert_raise(ExecutionError) do
      test_case.execute
    end
  end

  def test_regex
    name =  @test_case_request_text_with_regex.keys.first
    test_config = @test_case_request_text_with_regex[name]
    test_case = HttpBlackboxExecuter.new(name, test_config)
    assert_not_nil test_case
    response = IO.read("#{__dir__}/prometheus-metrics")
    stub_request(:get, "http://sampleurl/metrics").to_return(lambda do |_|
      return {
          body: response,
          status: 200
      }
    end)
    assert_nothing_raised do
      test_case.execute
    end

  end

  private

  def get_xml_doc(response_xml)
    Nokogiri::XML(response_xml) {|config| config.default_xml.noblanks}
  end

  def find_header_value_case_insensitve_key(key_name, headers)
    headers.each {|header_name, header_value| return header_value if header_name.downcase == key_name.downcase}
    nil
  end


end

#
# def test_get_200_with_header_test
#   # get first test case from yaml
#   test_case = TestCase.new(name, test_case)
#   assert_not_nil test_case
#   stub_request(:get, "http://sampleurl//health").to_return(status: 200)
#   test_case.execute
# end
#
#
# def test_full_plan
#   # get first test case from yaml
#   @test_plan_from_yaml.each do |name, test_case|
#     test_case = TestCase.new(name, test_case)
#     assert_not_nil test_case
#     stub_request(:get, "http://mock:8080/health").
#         to_return(status: 200)
#     test_case.execute
#   end
# end
#
#
# end

