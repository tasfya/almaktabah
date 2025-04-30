require 'rails_helper'

RSpec.describe Api::V1::ArticlesController, type: :request do
  describe 'GET /api/articles' do
    before do
      create_list(:article, 3)
    end

    it 'returns a list of articles' do
      get '/api/articles'

      expect(response).to have_http_status(:ok)
      expect(json_response).to be_an(Array)
      expect(json_response.size).to eq(3)
    end
  end

  describe 'GET /api/articles/:id' do
    let(:article) { create(:article) }

    context 'when the article exists' do
      it 'returns the requested article' do
        get "/api/articles/#{article.id}"

        expect(response).to have_http_status(:ok)
        expect(json_response).to have_key('id')
        expect(json_response['id']).to eq(article.id)
        expect(json_response['title']).to eq(article.title)
      end
    end

    context 'when the article does not exist' do
      it 'returns a not found error' do
        get '/api/articles/999'

        expect(response).to have_http_status(:not_found)
        expect(json_response).to include('error')
      end
    end
  end

  private

  def json_response
    JSON.parse(response.body)
  end
end
