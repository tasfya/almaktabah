require 'rails_helper'

RSpec.describe Api::V1::FatwasController, type: :request do
  describe 'GET /api/fatwas' do
    before do
      create_list(:fatwa, 3)
    end

    it 'returns a list of fatwas with metadata' do
      get '/api/fatwas'
      expect(response).to have_http_status(:ok)

      expect(json_response).to be_a(Hash)
      expect(json_response['fatwas']).to be_an(Array)
      expect(json_response['fatwas'].size).to eq(3)
      expect(json_response['meta']).to include('current_page', 'total_items', 'categories')
    end
  end

  describe 'GET /api/fatwas/:id' do
    let(:fatwa) { create(:fatwa) }

    context 'when the fatwa exists' do
      it 'returns the requested fatwa' do
        get "/api/fatwas/#{fatwa.id}"

        expect(response).to have_http_status(:ok)
        expect(json_response['id']).to eq(fatwa.id)
      end
    end

    context 'when the fatwa does not exist' do
      it 'returns a not found error' do
        get '/api/fatwas/999999'
        expect(response).to have_http_status(:not_found)
        expect(json_response).to include('error')
      end
    end
  end

  describe 'GET /api/fatwas?title=' do
    before do
      create(:fatwa, title: "Prayer Rules")
      create(:fatwa, title: "Fasting Guidelines")
    end

    it 'filters fatwas by title' do
      get '/api/fatwas', params: { title: 'prayer' }

      expect(response).to have_http_status(:ok)
      expect(json_response['fatwas'].size).to eq(1)
      expect(json_response['fatwas'][0]['title']).to match(/prayer/i)
    end
  end

  describe 'GET /api/fatwas/recent' do
    before do
      create_list(:fatwa, 12)
    end

    it 'returns 10 most recent fatwas' do
      get '/api/fatwas/recent'
      expect(response).to have_http_status(:ok)
      expect(json_response.size).to eq(5)
    end
  end

  private

  def json_response
    JSON.parse(response.body)
  end
end
