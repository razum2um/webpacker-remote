# frozen_string_literal: true

require 'webpacker/configuration'

class Webpacker::Remote::Configuration < Webpacker::Configuration
  # rubocop:disable Lint/MissingSuper
  def initialize(root_path:, config_path:, env:, **config_content)
    # deliberately not calling `super` just emulating what's done there
    # because we accept overloading to DI the content of `webpacker.yml` inline
    @root_path = root_path
    @config_path = config_path
    @env = env

    # addition
    @config_content = config_content
  end
  # rubocop:enable Lint/MissingSuper

  def load
    {
      cache_manifest: true,
      check_yarn_integrity: false,
      compile: false
    }.merge(@config_content)
  end

  # shakapacker error message
  def manifest_path
    public_manifest_path
  end

  # webpacker error message
  def public_manifest_path
    public_remote_manifest_path
  end

  private

  def public_remote_manifest_path
    File.join(root_path.to_s, config_path.to_s)
  end
end
