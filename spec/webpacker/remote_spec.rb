# frozen_string_literal: true

require 'spec_helper'

MAIN_CHUNK = "#{ROOT_PATH}/static/js/main.2e302672.chunk.js"

RSpec.describe Webpacker::Remote do
  let(:root_path) { ROOT_PATH }
  subject { described_class.new(root_path: root_path) }
  let(:manifest) { '../manifest.json' }

  def stub_network
    allow(Net::HTTP).to receive(:get_response).once.with(URI.parse(root_path)) do
      OpenStruct.new(body: File.read(File.expand_path(manifest, __dir__)))
    end
  end

  def stub_network_once_then_fail
    @responses = [OpenStruct.new(body: File.read(File.expand_path(manifest, __dir__)))]
    allow(Net::HTTP).to receive(:get_response).twice.with(URI.parse(root_path)) do
      @responses.shift || raise(Errno::ECONNREFUSED)
    end
  end

  shared_examples 'a manifest over unstable network' do
    before { stub_network_once_then_fail }

    describe '#manifest' do
      it 'can #refresh with network failures' do
        expect(subject.manifest.lookup('main', type: :javascript)).to eq MAIN_CHUNK
        expect(subject.manifest.refresh).to be_present
      end
    end
  end

  shared_examples 'a valid manifest' do
    before { stub_network }

    describe '#manifest' do
      it 'can #lookup assets' do
        expect(subject.manifest.lookup('main', type: :javascript)).to eq MAIN_CHUNK
      end

      it 'can #lookup_pack_with_chunks' do
        expect(subject.manifest.lookup_pack_with_chunks('main', type: :javascript)).to eq [
          "#{root_path}/static/js/runtime-main.1117032d.js",
          "#{root_path}/static/js/2.b92b8870.chunk.js",
          MAIN_CHUNK
        ]
      end

      it 'can #manifest_data exposes data with symbols/strings and defaults' do
        expect(subject.manifest.manifest_data['RANDOM_RELEASE_TAG_KEY']).to eq('RANDOM_RELEASE_TAG_VALUE')
      end
    end
  end

  describe 'with manifest v3' do
    it_behaves_like 'a valid manifest'
    it_behaves_like 'a manifest over unstable network'
  end

  describe 'with manifest v5' do
    let(:manifest) { '../webpack_assets_manifest_5.json' }
    it_behaves_like 'a valid manifest'
    # it_behaves_like 'a manifest over unstable network'
  end

  describe 'when config is cache_manifest: false' do
    subject { described_class.new(root_path: root_path, cache_manifest: false) }
    let(:request_count) { rand(3..5) }

    it 'can #lookup assets N times doing N requests' do
      expect(Net::HTTP).to receive(:get_response).exactly(request_count).times.with(URI.parse(root_path)) do
        OpenStruct.new(body: File.read(File.expand_path(manifest, __dir__)))
      end
      request_count.times do
        expect(subject.manifest.lookup('main', type: :javascript)).to eq MAIN_CHUNK
      end
    end

    it 'can #lookup assets N times doing at least one ok requests' do
      @responses = [OpenStruct.new(body: File.read(File.expand_path(manifest, __dir__)))]
      expect(Net::HTTP).to receive(:get_response).exactly(request_count).times.with(URI.parse(root_path)) do
        @responses.shift || raise(Errno::ECONNREFUSED)
      end
      request_count.times do
        expect(subject.manifest.lookup('main', type: :javascript)).to eq MAIN_CHUNK
      end
    end
  end

  describe 'with bad formatted uri to manifest' do
    let(:root_path) { '|' }

    it 'returns an empty manifest' do
      expect(subject.manifest.manifest_data).to be_blank
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
