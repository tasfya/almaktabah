require 'rails_helper'

RSpec.describe Api::V1::LecturesController, type: :request do
    let(:token) { create(:api_token) }
    describe 'GET /api/lectures' do
        before do
            create_list(:lecture, 3)
        end

        it 'returns a list of lectures with metadata' do
            get '/api/lectures', params: { api_token: token.token }
            expect(response).to have_http_status(:ok)

            expect(json_response).to be_a(Hash)
            expect(json_response['lectures']).to be_an(Array)
            expect(json_response['lectures'].size).to eq(3)
            expect(json_response['meta']).to include('current_page', 'total_items', 'categories')
        end
    end

    describe 'GET /api/lectures/:id' do
        let(:lecture) { create(:lecture) }

        context 'when the lecture exists' do
            it 'returns the requested lecture' do
                get "/api/lectures/#{lecture.id}", params: { api_token: token.token }

                expect(response).to have_http_status(:ok)
                expect(json_response['id']).to eq(lecture.id)
            end
        end

        context 'when the lecture does not exist' do
            it 'returns a not found error' do
                get '/api/lectures/999999', params: { api_token: token.token }
                expect(response).to have_http_status(:not_found)
                expect(json_response).to include('error')
            end
        end
    end

    describe 'GET /api/lectures?title=' do
        before do
            create(:lecture, title: "Ruby Programming")
            create(:lecture, title: "JavaScript Essentials")
        end

        it 'filters lectures by title' do
            get '/api/lectures', params: { title: 'ruby', api_token: token.token }

            expect(response).to have_http_status(:ok)
            expect(json_response['lectures'].size).to eq(1)
            expect(json_response['lectures'][0]['title']).to match(/ruby/i)
        end
    end

    describe 'GET /api/lectures/recent' do
        before do
            create_list(:lecture, 5)
        end

        it 'returns most recent lectures' do
            get '/api/lectures/recent', params: { api_token: token.token }
            expect(response).to have_http_status(:ok)
            expect(json_response.size).to eq(5)
        end
    end

    describe 'GET /api/lectures/most_viewed' do
        before do
            create_list(:lecture, 5)
        end

        it 'returns most viewed lectures' do
            get '/api/lectures/most_viewed', params: { api_token: token.token }
            expect(response).to have_http_status(:ok)
            expect(json_response.size).to eq(5)
        end
    end

    private

    def json_response
        JSON.parse(response.body)
    end
end
