# frozen_string_literal: true

require 'spec_helper'
require 'active_support/core_ext/string/output_safety' # SafeBuffer

MAIN_JAVASCRIPT_PACK_TAG = [
  "<script src='#{ROOT_PATH}/static/js/main.2e302672.chunk.js'>"
].freeze
ALL_JAVASCRIPT_CHUNCKS_TAG = [
  "<script src='#{ROOT_PATH}/static/js/runtime-main.1117032d.js'>",
  "<script src='#{ROOT_PATH}/static/js/2.b92b8870.chunk.js'>",
  "<script src='#{ROOT_PATH}/static/js/main.2e302672.chunk.js'>"
].freeze
MAIN_STYLESHEETS_PACK_TAG = [
  "<link href='#{ROOT_PATH}/static/css/main.de2ce207.chunk.css'>"
].freeze
ALL_STYLESHEETS_CHUNCKS_TAG = [
  "<link href='#{ROOT_PATH}/static/css/2.c639a3c9.chunk.css'>",
  "<link href='#{ROOT_PATH}/static/css/main.de2ce207.chunk.css'>"
].freeze

# Since shakapacker there's no chunks anymore, only _tag_ which returns chunks, see breaking change:
# https://github.com/shakacode/shakapacker/blob/712943ee9a0714e50ab68d899c8cc0a7292a9b28/docs/v6_upgrade.md
if ENV['WEBPACKER_GEM_VERSION'] =~ /shakapacker/
  JAVASCRIPT_PACK_TAG = ALL_JAVASCRIPT_CHUNCKS_TAG
  STYLESHEETS_PACK_TAG = ALL_STYLESHEETS_CHUNCKS_TAG
else
  JAVASCRIPT_PACK_TAG = MAIN_JAVASCRIPT_PACK_TAG
  STYLESHEETS_PACK_TAG = MAIN_STYLESHEETS_PACK_TAG
end

RSpec.describe Webpacker::Remote::Helper do
  let(:root_path) { ROOT_PATH }
  let(:webpacker) { Webpacker::Remote.new(root_path: root_path) }
  let(:manifest) { '../../manifest.json' }

  before do
    allow(Net::HTTP).to receive(:get_response).with(URI.parse(root_path)) do
      OpenStruct.new(body: File.read(File.expand_path(manifest, __dir__)))
    end
  end

  # railsy deps of lib/webpacker/helper.rb in shakapacker
  let(:klass) do
    Class.new do
      attr_accessor :output_buffer

      include Webpacker::Helper

      # active_support/core_ext/array/extract_options.rb
      def extract_options!(arr)
        if arr.last.is_a?(Hash) && arr.last.instance_of?(Hash)
          arr.pop
        else
          {}
        end
      end

      # emulate railsy interface
      def javascript_include_tag(*sources)
        extract_options!(sources)
        sources.map { |src| "<script src='#{src}'>".html_safe }
      end

      # emulate railsy interface
      def stylesheet_link_tag(*sources)
        extract_options!(sources)
        sources.map { |src| "<link href='#{src}'>".html_safe }
      end

      # emulate railsy action_view interface
      # lib/action_view/helpers/capture_helper.rb
      def capture(*args)
        value = nil
        buffer = with_output_buffer { value = yield(*args) }
        return unless (string = buffer.presence || value) && string.is_a?(String)

        ERB::Util.html_escape string
      end

      # emulate railsy action_view interface
      # lib/action_view/helpers/text_helper.rb
      def concat(string)
        Array(string).each { |s| output_buffer << s }
        output_buffer
      end

      # emulate railsy action_view interface, using a String instead of `ActionView::OutputBuffer``
      # only enough to be used `capture` and `concat`
      # see lib/action_view/buffers.rb
      def with_output_buffer(buf = nil) # :nodoc:
        buf ||= ActiveSupport::SafeBuffer.new
        self.output_buffer = buf
        old_buffer = output_buffer
        yield
        output_buffer
      ensure
        self.output_buffer = old_buffer
      end
    end
  end

  subject { klass.new.tap { |instance| instance.output_buffer = ActiveSupport::SafeBuffer.new } }

  describe '#javascript_pack_tag' do
    it 'respects additional :webpacker parameter' do
      expect(subject.javascript_pack_tag('main', type: :javascript, webpacker: webpacker)).to eq_joined(
        JAVASCRIPT_PACK_TAG
      )
    end
  end

  describe '#javascript_packs_with_chunks_tag' do
    if (webpacker_version = ENV['WEBPACKER_GEM_VERSION']) =~ /shakapacker/
      pending "cannot be used if WEBPACKER_GEM_VERSION=#{webpacker_version.inspect}"
    else
      it 'respects additional :webpacker parameter' do
        expect(subject.javascript_packs_with_chunks_tag('main', type: :javascript, webpacker: webpacker)).to eq_joined(
          ALL_JAVASCRIPT_CHUNCKS_TAG
        )
      end
    end
  end

  describe '#stylesheet_pack_tag' do
    it 'respects additional :webpacker parameter' do
      expect(subject.stylesheet_pack_tag('main', type: :stylesheet, webpacker: webpacker)).to eq_joined(
        STYLESHEETS_PACK_TAG
      )
    end
  end

  describe '#stylesheet_packs_with_chunks_tag' do
    if (webpacker_version = ENV['WEBPACKER_GEM_VERSION']) =~ /shakapacker/
      pending "cannot be used if WEBPACKER_GEM_VERSION=#{webpacker_version.inspect}"
    else
      it 'respects additional :webpacker parameter' do
        expect(subject.stylesheet_packs_with_chunks_tag('main', type: :stylesheet, webpacker: webpacker)).to eq_joined(
          ALL_STYLESHEETS_CHUNCKS_TAG
        )
      end
    end
  end

  describe 'with bad manifest content structure' do
    let(:manifest) { '../../corrupted_manifest.json' }

    it 'returns nil silently to get rails ability to pick up using asset-pipeline' do
      expect do
        subject.javascript_pack_tag('main', type: :javascript, webpacker: webpacker)
      end.to raise_error(Webpacker::Manifest::MissingEntryError, /(Webpacker|Shakapacker) can't find main.* in https:..example.com../)
    end
  end
end
