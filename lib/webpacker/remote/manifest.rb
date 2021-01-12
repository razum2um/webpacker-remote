# frozen_string_literal: true

require 'webpacker/manifest'

class Webpacker::Remote::Manifest < Webpacker::Manifest
  def load
    @webpacker.public_manifest_content
  end
end
