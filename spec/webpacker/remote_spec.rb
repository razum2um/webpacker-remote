# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Webpacker::Remote do
  let(:root_path) { 'https://example.com' }
  subject { described_class.new(root_path: root_path) }
  let(:manifest) { '../manifest.json' }

  shared_examples 'a valid manifest' do
    before do
      allow(Net::HTTP).to receive(:get_response).with(URI.parse(root_path)) do
        OpenStruct.new(body: File.read(File.expand_path(manifest, __dir__)))
      end
    end

    describe '#manifest' do
      it 'cannot #lookup assets' do
        expect(subject.manifest.lookup('main', type: :javascript)).to eq "#{root_path}/static/js/main.2e302672.chunk.js"
      end

      it 'can #lookup_pack_with_chunks' do
        expect(subject.manifest.lookup_pack_with_chunks('main', type: :javascript)).to eq [
          "#{root_path}/static/js/runtime-main.1117032d.js",
          "#{root_path}/static/js/2.b92b8870.chunk.js",
          "#{root_path}/static/js/main.2e302672.chunk.js"
        ]
      end
    end
  end

  describe 'with manifest v3' do
    it_behaves_like 'a valid manifest'
  end

  describe 'with manifest v5' do
    let(:manifest) { '../webpack_assets_manifest_5.json' }
    it_behaves_like 'a valid manifest'
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
