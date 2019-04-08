#!/usr/bin/env ruby
require 'rubygems'
require 'yaml'
require './http_blackbox_executer.rb'
require './execution_error.rb'

DEBUG = ENV['DEBUG']
TEST_DIR = (ENV['TEST_DIR'] || (raise 'required [TEST_DIR] environment variable not set!'))
puts "*** TEST_DIR =#{TEST_DIR} (test-plan.yaml + supporting test files expected in this directory) ***"
test_plan_path = "#{TEST_DIR}/test-plan.yaml"
raise "required file [#{test_plan_path}] not found!" unless File.exist? test_plan_path
test_plan = YAML.load_file(test_plan_path)

puts test_plan
test_plan.each {|name, test_case|
  begin
    test_case = HttpBlackboxExecuter.new(name, test_case)
    #todo perhaps create and validate before executing any, execute in a new loop
    test_case.execute
  rescue Exception => e
    #todo if debug turned on pass print backtrace
    puts "Test failure in test case #{name}: #{e.message}\n"
    if DEBUG
      raise e
    end
    exit 1
  end
}
puts "Test Execution Success!".center(80, "-")
