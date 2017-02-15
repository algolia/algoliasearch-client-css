require 'awesome_print'
require 'fileutils'
require_relative '../lib/query_parser.rb'

RSpec.configure do |config|
  config.filter_run(focus: true)
  config.fail_fast = true
  config.run_all_when_everything_filtered = true
end
