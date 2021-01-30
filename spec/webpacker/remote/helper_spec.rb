# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Webpacker::Remote::Helper do
  let(:root_path) { 'https://example.com' }
  let(:webpacker) { Webpacker::Remote.new(root_path: root_path) }

  before do
    allow(Net::HTTP).to receive(:get_response).with(URI.parse(root_path)) do
      OpenStruct.new(body: File.read(File.expand_path('../../manifest.json', __dir__)))
    end
  end

  let(:klass) do
    Class.new do
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
        sources.map { |src| "<script src='#{src}'>" }
      end

      # emulate railsy interface
      def stylesheet_link_tag(*sources)
        extract_options!(sources)
        sources.map { |src| "<link href='#{src}'>" }
      end
    end
  end

  subject { klass.new }

  describe '#javascript_pack_tag' do
    it 'respects additional :webpacker parameter' do
      expect(subject.javascript_pack_tag('main', type: :javascript, webpacker: webpacker)).to eq [
        "<script src='#{root_path}/static/js/main.2e302672.chunk.js'>"
      ]
    end
  end

  describe '#javascript_packs_with_chunks_tag' do
    it 'respects additional :webpacker parameter' do
      expect(subject.javascript_packs_with_chunks_tag('main', type: :javascript, webpacker: webpacker)).to eq [
        "<script src='#{root_path}/static/js/runtime-main.1117032d.js'>",
        "<script src='#{root_path}/static/js/2.b92b8870.chunk.js'>",
        "<script src='#{root_path}/static/js/main.2e302672.chunk.js'>"
      ]
    end
  end

  describe '#stylesheet_pack_tag' do
    it 'respects additional :webpacker parameter' do
      expect(subject.stylesheet_pack_tag('main', type: :stylesheet, webpacker: webpacker)).to eq [
        "<link href='#{root_path}/static/css/main.de2ce207.chunk.css'>"
      ]
    end
  end

  describe '#stylesheet_packs_with_chunks_tag' do
    it 'respects additional :webpacker parameter' do
      expect(subject.stylesheet_packs_with_chunks_tag('main', type: :stylesheet, webpacker: webpacker)).to eq [
        "<link href='#{root_path}/static/css/2.c639a3c9.chunk.css'>",
        "<link href='#{root_path}/static/css/main.de2ce207.chunk.css'>"
      ]
    end
  end
end
