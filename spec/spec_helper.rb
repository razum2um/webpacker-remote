# frozen_string_literal: true

require 'simplecov'
SimpleCov.start

ROOT_PATH = 'https://example.com'

if ENV['CI'] && ENV['CODECOV_TOKEN']
  require 'codecov'
  SimpleCov.formatter = SimpleCov::Formatter::Codecov
end

require 'bundler/setup'
begin
  require 'pry-byebug'
rescue LoadError
  nil
end

require 'webpacker/remote'

if ENV['WEBPACKER_GEM_VERSION'] =~ /shakapacker/
  # by default `shakapacker` is tight to rails too much :'(
  require 'active_support/core_ext/object/inclusion'
  require 'active_support/core_ext/string/output_safety' # SafeBuffer, String#html_safe
  module Rails
    module_function

    def env
      'production'
    end

    def root
      Pathname.new('/non-existing-rails-root')
    end
  end
end

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = '.rspec_status'

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  if ENV['WEBPACKER_GEM_VERSION'] =~ /shakapacker/
    config.before do
      # shakapacker unavoidably reads the config :'(
      tmp_webpacker_yml = Tempfile.new
      tmp_webpacker_yml.write(YAML.dump(Rails.env => ::Webpacker::Instance.new.config.send(:defaults).to_hash))
      tmp_webpacker_yml.flush

      # def initialize(root_path: Rails.root, config_path: Rails.root.join("config/webpacker.yml"))
      Webpacker.instance = ::Webpacker::Instance.new(config_path: Pathname.new(tmp_webpacker_yml.path))
    end
  end
end

RSpec::Matchers.define :eq_joined do |expected|
  match do |actual|
    values_match? Array(actual).join, Array(expected).join
  end
end
