# frozen_string_literal: true

require 'webpacker/configuration'

class Webpacker::Remote::Configuration < Webpacker::Configuration
  def load
    {
      cache_manifest: true,
      check_yarn_integrity: false,
      compile: false
    }
  end
end
