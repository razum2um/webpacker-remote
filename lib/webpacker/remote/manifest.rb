# frozen_string_literal: true

require 'webpacker/manifest'

class Webpacker::Remote::Manifest < Webpacker::Manifest
  def load
    @webpacker.public_manifest_content
  end

  def lookup_pack_with_chunks(name, pack_type = {})
    return unless (paths = super)

    paths.map { |p| File.join(config.root_path.to_s, p) }
  end

  def lookup(name, pack_type = {})
    return unless (path = super)

    File.join(config.root_path.to_s, path)
  end
end
