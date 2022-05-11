# frozen_string_literal: true

# better version of https://github.com/rails/webpacker/issues/2054#issuecomment-564173103
# rewrite all methods by accept direct injection instead of calling `current_webpacker_instance`
# because we can have same layout with script/link tags from different webpackers
require 'webpacker/helper'
module Webpacker::Remote::Helper
  METHODS = %i[
    javascript_pack_tag
    javascript_packs_with_chunks_tag
    stylesheet_pack_tag
    stylesheet_packs_with_chunks_tag
  ].freeze

  METHODS.select { |meth| ::Webpacker::Helper.instance_methods.include?(meth) }.each do |meth|
    define_method meth do |*names, **options|
      return super(*names, **options) unless options[:webpacker]

      new_helper = dup
      new_helper.define_singleton_method(:current_webpacker_instance) do
        options[:webpacker]
      end
      new_helper.send(meth, *names, **options.except(:webpacker))
    end
  end
end

Webpacker::Helper.prepend Webpacker::Remote::Helper unless ENV['SKIP_WEBPACKER_HELPER_OVERRIDE']
