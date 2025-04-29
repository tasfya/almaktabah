require 'rails_helper'
require 'api/api_constraints'

RSpec.describe Api::ApiConstraints do
  describe '#matches?' do
    let(:version) { 1 }

    context 'when default is true' do
      let(:api_constraints) { described_class.new(version: version, default: true) }

      it 'returns true regardless of the request headers' do
        request = double('request', headers: {})
        expect(api_constraints.matches?(request)).to be true
      end
    end

    context 'when default is false' do
      let(:api_constraints) { described_class.new(version: version, default: false) }

      context 'when request has correct Accept header' do
        it 'returns true for matching version' do
          request = double('request', headers: { 'Accept' => 'application/vnd.almaktabah.v1' })
          expect(api_constraints.matches?(request)).to be true
        end
      end

      context 'when request has incorrect Accept header' do
        it 'returns false for non-matching version' do
          request = double('request', headers: { 'Accept' => 'application/vnd.almaktabah.v2' })
          expect(api_constraints.matches?(request)).to be false
        end
      end
    end
  end
end
