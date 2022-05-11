# frozen_string_literal: true

require 'webpacker/manifest'

class Webpacker::Remote::Manifest < Webpacker::Manifest
  def load
    # load from network, upstream version operates pathnames:
    # if config.manifest_path.exist?
    #   JSON.parse config.manifest_path.read
    # else
    #   {}
    # end
    if public_manifest_content_uri
      public_manifest_content
    else
      {}
    end
  end

  def public_manifest_content
    JSON.parse(Net::HTTP.get_response(public_manifest_content_uri).body)
  rescue JSON::ParserError, Errno::ECONNREFUSED, Net::OpenTimeout, Net::ReadTimeout, Errno::ENOENT => e
    raise Webpacker::Remote::Error, <<~MSG
      having {root_path: #{config.root_path.inspect}, config_path: #{config.config_path.inspect}}
      #{e.class}: #{e.message}
    MSG
  end

  def lookup_pack_with_chunks(name, pack_type = {})
    # `super` method copy
    manifest_pack_type = manifest_type(pack_type[:type])
    manifest_pack_name = manifest_name(name, manifest_pack_type)
    assets = find('entrypoints')[manifest_pack_name]
    # patched super behavior:
    # - keys in webpack-assets-manifest-3: entrypoints.main.{js/css}
    # - keys in webpack-assets-manifest-5: entrypoints.main.assets.{js/css}
    # `shakapacker` just has this inline:
    # find("entrypoints")[manifest_pack_name]["assets"][manifest_pack_type]
    assets = assets['assets'] if assets.key?('assets')
    paths = assets[manifest_pack_type]
    # end of `super` method copy

    # remote-webpacker addition: full URIs
    # railsy webpacker returns relative paths from its manifest
    # because `action_view` resolves them using `config.action_controller.asset_host`
    # but remote-webpacker tuned to have bundles from several locations
    paths.map { |p| File.join(config.root_path.to_s, p) }
  rescue NoMethodError
    nil
  end

  def lookup(name, pack_type = {})
    return unless (path = super)

    File.join(config.root_path.to_s, path)
  end

  # additional api to be able to put additional data into the manifest
  # because `find` and `data` are private
  def manifest_data
    data
  end

  private

  def public_manifest_content_uri
    URI.parse(File.join(config.root_path.to_s, config.config_path.to_s))
  rescue URI::InvalidURIError
    nil
  end
end
