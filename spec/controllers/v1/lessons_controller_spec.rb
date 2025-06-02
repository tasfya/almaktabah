require 'rails_helper'

RSpec.describe Api::V1::LessonsController, type: :request do
  let(:token) { create(:api_token) }
  describe 'GET /api/lessons' do
    let(:series) { create(:series) }

    before do
      create_list(:lesson, 3, series: series)
    end

    it 'returns a list of lessons with metadata' do
      get '/api/lessons', params: { api_token: token.token }
      expect(response).to have_http_status(:ok)

      expect(json_response).to be_a(Hash)
      expect(json_response['lessons']).to be_an(Array)
      expect(json_response['lessons'].size).to eq(3)
      expect(json_response['meta']).to include('current_page', 'total_items', 'categories')
    end
  end

  describe 'GET /api/lessons/:id' do
    let(:lesson) { create(:lesson) }

    context 'when the lesson exists' do
      it 'returns the requested lesson' do
        get "/api/lessons/#{lesson.id}", params: { api_token: token.token }

        expect(response).to have_http_status(:ok)
        expect(json_response['id']).to eq(lesson.id)
      end
    end

    context 'when the lesson does not exist' do
      it 'returns a not found error' do
        get '/api/lessons/999999', params: { api_token: token.token }
        expect(response).to have_http_status(:not_found)
        expect(json_response).to include('error')
      end
    end
  end

  describe 'GET /api/lessons?title=' do
    before do
      create(:lesson, title: "Ruby Basics")
      create(:lesson, title: "JavaScript Intro")
    end

    it 'filters lessons by title' do
      get '/api/lessons', params: { title: 'ruby', api_token: token.token }

      expect(response).to have_http_status(:ok)
      expect(json_response['lessons'].size).to eq(1)
      expect(json_response['lessons'][0]['title']).to match(/ruby/i)
    end
  end

  describe 'GET /api/lessons/recent' do
    before do
      create_list(:lesson, 12)
    end

    it 'returns 10 most recent lessons' do
      get '/api/lessons/recent', params: { api_token: token.token }
      expect(response).to have_http_status(:ok)
      expect(json_response.size).to eq(10)
    end
  end

  private

  def json_response
    JSON.parse(response.body)
  end
end
