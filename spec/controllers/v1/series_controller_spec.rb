require 'rails_helper'

RSpec.describe Api::V1::SeriesController, type: :request do
  let(:token) { create(:api_token) }
  describe 'GET /api/series' do
    before do
      create_list(:series, 3)
    end

    it 'returns a list of series with metadata' do
      get '/api/series', params: { api_token: token.token }
      expect(response).to have_http_status(:ok)

      expect(json_response).to be_a(Hash)
      expect(json_response['series']).to be_an(Array)
      expect(json_response['series'].size).to eq(3)
      expect(json_response['meta']).to include('current_page', 'total_items', 'categories')
    end
  end

  describe 'GET /api/series/:id' do
    let(:series) { create(:series) }

    context 'when the series exists' do
      it 'returns the requested series' do
        get "/api/series/#{series.id}", params: { api_token: token.token }

        expect(response).to have_http_status(:ok)
        expect(json_response['id']).to eq(series.id)
      end
    end

    context 'when the series does not exist' do
      it 'returns a not found error' do
        get '/api/series/999999', params: { api_token: token.token }
        expect(response).to have_http_status(:not_found)
        expect(json_response).to include('error')
      end
    end
  end

  describe 'GET /api/series?title=' do
    before do
      create(:series, title: "Fundamentals of Fiqh")
      create(:series, title: "Arabic Grammar Principles")
    end

    it 'filters series by title' do
      get '/api/series', params: { title: 'fiqh', api_token: token.token }

      expect(response).to have_http_status(:ok)
      expect(json_response['series'].size).to eq(1)
      expect(json_response['series'][0]['title']).to match(/fiqh/i)
    end
  end

  describe 'GET /api/series?category=' do
    before do
      create(:series, category: "Fiqh")
      create(:series, category: "Aqeedah")
    end

    it 'filters series by category' do
      get '/api/series', params: { category: 'fiqh', api_token: token.token }

      expect(response).to have_http_status(:ok)
      expect(json_response['series'].size).to eq(1)
      expect(json_response['series'][0]['category']).to match(/fiqh/i)
    end
  end

  private

  def json_response
    JSON.parse(response.body)
  end
end
