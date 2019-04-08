require 'rest-client'
require 'diffy'
require 'nokogiri'
require 'equivalent-xml'
require 'json'
require_relative 'validation_error'
require_relative 'execution_error'


class HttpBlackboxExecuter
  TOP_LEVEL_REQUIRED_FIELDS = %w(request expectedResponse)
  REQUIRED_REQUEST_FIELDS = %w(url method)
  OPTIONAL_REQUEST_FIELDS = %w(type filePath headers)
  ALL_REQUEST_FIELDS = REQUIRED_REQUEST_FIELDS | OPTIONAL_REQUEST_FIELDS
  REQUIRED_RESPONSE_FIELDS = %w(statusCode)
  OPTIONAL_RESPONSE_FIELDS = %w(maxRetryCount filePath headers type ignoreAttributes ignoreElements xpath)
  ALL_RESPONSE_FIELDS = REQUIRED_RESPONSE_FIELDS | OPTIONAL_RESPONSE_FIELDS
  HTTP_METHODS = %w(post get delete patch put)
  attr_accessor :test_case_config

  def initialize(name, test_case_config)
    test_case_as_json = JSON.parse(JSON.dump(test_case_config)) # convert symbols to strings
    validate(name, test_case_as_json)
    @test_case_config = test_case_as_json
    @name = name
  end

#todo, print config
#todo print ignored, invalid config
  def validate(name, test_case)
    raise ValidationError.new("test-plan.yaml/#{name } top level keys don't match required keys.  observed: #{test_case.keys.sort}, required: #{TOP_LEVEL_REQUIRED_FIELDS}") unless test_case.keys.sort == TOP_LEVEL_REQUIRED_FIELDS.sort
    #iterate all top level fields
    test_case.each do |field, value|
      case field.to_s
      when 'request'
        validate_request_config(name, value)
      when 'expectedResponse'
        validate_response_config(name, value)
      else
        raise ValidationError.new("test-plan.yaml/#{name } top level keys don't match required keys.  observed: [#{field}], required: #{TOP_LEVEL_REQUIRED_FIELDS}")
      end
    end

  end


  def execute
    puts "Executing test [#{@name}]".center(80, "-")
    request = @test_case_config['request']
    expected_response = @test_case_config['expectedResponse']
    execute_request(request, expected_response)
  end

  def execute_request(request_config, expected_response_config)
    url = request_config['url']
    http_method = request_config['method']
    expected_status_code = expected_response_config['statusCode']
    raise ValidationError.new "Test case [#{@name}], HTTP method #{http_method} invalid" unless HTTP_METHODS.include?(http_method.downcase)
    # todo ----->  consolidate with http modify method req <-----

    case http_method
    when "get"
      max_retry_count = expected_response_config['maxRetryCount'] || 0
      payload = get_payload_from_config(request_config, "request")
      actual_response = handle_get_request(url, expected_status_code, max_retry_count, payload, request_config['headers'])
      test_response(actual_response, expected_response_config)
    else
      payload = get_payload_from_config(request_config, "request")
      #todo add in max_retry_count
      actual_response = handle_http_modify_method_request(url, http_method, expected_status_code, payload, request_config['headers'])
      test_response(actual_response, expected_response_config)
    end
  end

  def get_payload_from_config(config, config_type)
    payload_path = config['filePath']
    if payload_path
      raise ValidationError.new "Test case [#{@name}], #{config_type} filePath #{payload_path} not found!" unless File.exist? payload_path
      IO.read(payload_path)
    else
      nil
    end
  end

# todo ----->  consolidate with http modify method req <-----
  def handle_get_request(url, expectedHttpStatusCode, max_retry_count, payload, headers)
    puts "Sending Http get to #{url}..."
    begin
      retries ||= 0
      puts "try ##{ retries + 1 }" if retries > 0
      puts "http check:[#{url}]"
      #todo what should timeout be set to?  should this be conigurable?
      # configured headers need to be capitalized per ruby HTTP client
      response = RestClient::Request.execute(method: :get, url: url,
                                             timeout: 2, payload: payload, headers: headers) {
          |response| response
      }
      raise ExecutionError.new "HTTP Response code [#{response.code}] received, expected [#{expectedHttpStatusCode}]" if response.code != expectedHttpStatusCode
      puts "Expected status code [#{expectedHttpStatusCode}] verified."
      return response
    rescue Exception => e
      puts e.backtrace
      if (retries += 1) < max_retry_count
        sleep 1
        retry
      end
      raise ExecutionError.new("Max retries hit on get call to #{url}")
    end

  end

  def handle_http_modify_method_request(url, method, expectedHttpStatusCode, payload, headers)
    puts "Sending Http #{method} to #{url}..."
    response = RestClient::Request.execute(method: method, url: url, payload: payload, headers: headers) {|response| response}
    raise ExecutionError.new("HTTP Response code [#{response.code}] received, expected [#{expectedHttpStatusCode}]") if response.code != expectedHttpStatusCode
    puts "Expected status code [#{expectedHttpStatusCode}] verified."
    response
  end

  def test_response(actual_response, expected_response_config)
    #if no filePath is specified in the expected_response_config then nothing to test
    expected_response_path = expected_response_config['filePath']
    actual_response_text = actual_response.body
    check_headers(expected_response_config['headers'], actual_response.raw_headers)
    unless expected_response_path.nil?
      type = expected_response_config['type']
      raise ValidationError.new("expected response missing [type], valid values:  valid: ['text', 'json', 'xml']") if type.nil?
      expected_response_text = (File.exist? expected_response_path) ? File.read(expected_response_path) : (raise ValidationError.new("Expected response path [#{expected_response_path}] not found!"))
      case expected_response_config['type']
      when 'text'
        check_text(actual_response_text, expected_response_text)
      when 'xml'
        ignore_attributes = expected_response_config['ignoreAttributes']
        ignore_elements = expected_response_config['ignoreElements']
        xpath_config = expected_response_config['xpath']
        check_xml(actual_response_text, expected_response_text, ignore_attributes, ignore_elements, xpath_config)
      when 'json'
        raise "not implemented"
      else
        raise ValidationError.new("invalid response type: [#{expected_response_config['type']}] , valid: ['text', 'json', 'xml']")
      end
    end
  end

  def check_headers(expected_headers, actual_response_headers)
    expected_headers&.each do |expected_key, expected_value|
      found = false
      actual_response_headers.each do |actual_key, actual_value|
        if actual_key.to_s.downcase == expected_key.downcase
          raise ExecutionError.new("Header check failed for Expected Header [#{expected_key}].  Expected value: [#{expected_value}], Observed Value: [#{actual_value.first}]") unless actual_value.include? expected_value
          found = true
          break
        end
      end
      raise ExecutionError.new "expected header [#{expected_key}] not found.  Observed headers: #{actual_response_headers.keys}" unless found
    end
  end

  def check_text(actual_response, expected_response)
    text_actual_expected_mismatch(actual_response, expected_response) if (actual_response != expected_response)
  end

  def text_actual_expected_mismatch(actual_response, expected_response)
    puts "Error: actual response doesn't match expected response".center(80, '-')
    puts "start expected doc".center(80, "-")
    puts expected_response
    puts "end expected doc".center(80, "-")
    puts "start actual response".center(80, "-")
    puts actual_response
    puts "end actual response".center(80, "-")
    puts "differences ".center(80, "-")
    puts Diffy::Diff.new(expected_response, actual_response)
    raise ExecutionError.new("Error, test failure.")
  end

  def check_xpath(xml_text, xpath_config)
    expected_doc = Nokogiri::XML(xml_text) {|config| config.default_xml.noblanks}
    xpath_config&.each do |xpath, expected_value|
      observed_value = expected_doc.xpath(xpath).to_s
      raise ExecutionError.new "xpath expression [#{xpath}] expected [#{expected_value}], observed: [#{observed_value}]" unless observed_value == expected_value
    end
  end

  def check_xml(actual_response_text, expected_response_text, ignore_attributes, ignore_elements, xpath_config = nil)
    check_expected_vs_actual(actual_response_text, expected_response_text, ignore_attributes, ignore_elements)
    check_xpath(actual_response_text, xpath_config)
  end

  def check_json(actual_response, expected_response)

  end

  private

  def check_expected_vs_actual(actual_response_text, expected_response_text, ignore_attributes, ignore_elements)
    if expected_response_text
      actual_response_doc = Nokogiri::XML(actual_response_text) {|config| config.default_xml.noblanks}
      expected_doc = Nokogiri::XML(expected_response_text) {|config| config.default_xml.noblanks}
      equivalent = EquivalentXml.equivalent?(actual_response_doc, expected_doc, opts = {:element_order => false, :normalize_whitespace => true, :ignore_attr_values => ignore_attributes, :ignore_content => ignore_elements})
      if equivalent
        puts "Actual response matches expected response"
      else
        puts "start expected doc".center(80, "-")
        puts expected_doc.to_s
        puts "end expected doc".center(80, "-")
        puts '-' * 80
        puts "Error: actual response doesn't match expected response"
        puts "start actual response".center(80, "-")
        puts actual_response_doc.to_s
        puts "end actual response".center(80, "-")
        puts "differences ".center(80, "-")
        puts Diffy::Diff.new(expected_doc.to_s, actual_response_doc.to_s)
        raise ExecutionError.new("Error, test failure.")
      end
    end
  end

  def validate_response_config(test_name, response_config)
    REQUIRED_RESPONSE_FIELDS.each do |req_response_field|
      raise ValidationError.new "test-plan.yaml: Error in [#{test_name}], required response config key [#{req_response_field}] missing.  required: #{REQUIRED_RESPONSE_FIELDS}" unless response_config.keys.include? req_response_field.to_s
    end
    response_config.keys.each do |response_field|
      raise ValidationError.new "test-plan.yaml: Error in [#{test_name}], response field [#{response_field}] invalid" unless ALL_RESPONSE_FIELDS.include? response_field.to_s
    end
    if response_config.keys.include?('filePath')
      raise ValidationError.new "test-plan.yaml: Error in [#{test_name}], response field [type] is missing. It is required if a [filePath] is configured." unless response_config.keys.include?('type')
    end
    if response_config.keys.include?('type')
      raise ValidationError.new "test-plan.yaml: Error in [#{test_name}], response field [filePath] is missing. It is equired if a [type] is configured." unless response_config.keys.include?('type')
    end
  end

  def validate_request_config(test_name, request_config)
    request_config.keys.each do |request_field|
      raise ValidationError.new "test-plan.yaml: Error in [#{test_name}], reqeust field [#{request_field}] invalid" unless ALL_REQUEST_FIELDS.include? request_field.to_s
    end
    REQUIRED_REQUEST_FIELDS.each do |required_request_field|
      raise ValidationError.new "test-plan.yaml: Error in [#{test_name}], required request config key [#{required_request_field}] is missing. required: #{REQUIRED_REQUEST_FIELDS}" unless request_config.keys.include? required_request_field.to_s
    end
    if request_config.keys.include?('filePath')
      raise ValidationError.new "test-plan.yaml: Error in [#{test_name}], request field [type] is missing. It is required if a [filePath] is configured." unless request_config.keys.include?('type')
    end
    if request_config.keys.include?('type')
      raise ValidationError.new "test-plan.yaml: Error in [#{test_name}], request field [filePath] is missing. It is required if a [type] is configured." unless request_config.keys.include?('type')
    end

  end
end


