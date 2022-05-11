# frozen_string_literal: true

require 'webpacker/manifest'

class Webpacker::Remote::Manifest < Webpacker::Manifest
  def load
    @webpacker.public_manifest_content
  end

  def lookup_pack_with_chunks(name, pack_type = {})
    # `super` method copy
    manifest_pack_type = manifest_type(pack_type[:type])
    manifest_pack_name = manifest_name(name, manifest_pack_type)
    assets = find('entrypoints')[manifest_pack_name]
    # patched super behavior:
    # - keys in webpack-assets-manifest-3: entrypoints.main.{js/css}
    # - keys in webpack-assets-manifest-5: entrypoints.main.assets.{js/css}
    assets = assets['assets'] if assets.key?('assets')
    paths = assets[manifest_pack_type]
    # end of `super` method copy

    paths.map { |p| File.join(config.root_path.to_s, p) }
  rescue NoMethodError
    nil
  end

  def lookup(name, pack_type = {})
    return unless (path = super)

    File.join(config.root_path.to_s, path)
  end
end
