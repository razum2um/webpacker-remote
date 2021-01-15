# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Webpacker::Remote do
  let(:uri) { 'https://example.com' }
  subject { described_class.new(uri: uri) }

  describe 'with valid manifest' do
    before do
      allow(Net::HTTP).to receive(:get_response).with(URI.parse(uri)) do
        OpenStruct.new(body: File.read(File.expand_path('../manifest.json', __dir__)))
      end
    end

    describe '#manifest' do
      it 'cannot #lookup assets' do
        expect(subject.manifest.lookup('main', type: :javascript)).to eq 'static/js/main.2e302672.chunk.js'
      end

      it 'can #lookup_pack_with_chunks' do
        expect(subject.manifest.lookup_pack_with_chunks('main', type: :javascript)).to eq [
          'static/js/runtime-main.1117032d.js',
          'static/js/2.b92b8870.chunk.js',
          'static/js/main.2e302672.chunk.js'
        ]
      end
    end
  end

  describe 'with invalid manifest' do
    before do
      allow(Net::HTTP).to receive(:get_response) do
        raise Net::OpenTimeout, 'wtf'
      end
    end

    it 'raises early' do
      expect { subject }.to raise_error(Webpacker::Remote::Error, /wtf/)
    end
  end
end
