# frozen_string_literal: true

require 'json'
require 'uri'
require 'net/http'
require 'webpacker'

class Webpacker::Remote < Webpacker::Instance
  require 'webpacker/remote/manifest'
  require 'webpacker/remote/configuration'
  require 'webpacker/remote/helper'

  VERSION = '0.1.0'

  class Error < StandardError; end

  # rubocop:disable Lint/MissingSuper
  def initialize(root_path: nil, config_path: nil, **config_content)
    # deliberately not calling `super` just emulating what's done there
    # otherwise defaults in super initialize would call `Rails`
    # let's unbind the gem from rails
    @config_path = config_path
    @root_path = root_path

    # additions
    @config_content = config_content.symbolize_keys
    # fetch manifest eagerly to fail fast in initiazer unless cache_manifest: false
    manifest.manifest_data if @config_content.fetch(:cache_manifest, true)
  end
  # rubocop:enable Lint/MissingSuper

  def manifest
    @manifest ||= Webpacker::Remote::Manifest.new(self)
  end

  def config
    @config ||= Webpacker::Remote::Configuration.new(
      root_path: root_path,
      config_path: config_path,
      **config_content
    )
  end

  # right now this only supports builds done ahead of time
  def env
    'production'
  end

  private

  def config_content
    { env: env }.merge(@config_content)
  end
end
