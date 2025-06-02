require 'rails_helper'

RSpec.describe Api::V1::BenefitsController, type: :request do
    let(:token) { create(:api_token) }
    describe 'GET /api/benefits' do
        before do
            create_list(:benefit, 3)
        end

        it 'returns a list of benefits with metadata' do
            get "/api/benefits?api_token=#{token.token}"
            expect(response).to have_http_status(:ok)

            expect(json_response).to be_a(Hash)
            expect(json_response['benefits']).to be_an(Array)
            expect(json_response['benefits'].size).to eq(3)
            expect(json_response['meta']).to include('current_page', 'total_items', 'categories')
        end
    end

    describe 'GET /api/benefits/:id' do
        let(:benefit) { create(:benefit) }

        context 'when the benefit exists' do
            it 'returns the requested benefit' do
                get "/api/benefits/#{benefit.id}?api_token=#{token.token}"
                expect(response).to have_http_status(:ok)
                expect(json_response['id']).to eq(benefit.id)
            end
        end

        context 'when the benefit does not exist' do
            it 'returns a not found error' do
                get "/api/benefits/999999?api_token=#{token.token}"
                expect(response).to have_http_status(:not_found)
                expect(json_response).to include('error')
            end
        end
    end

    describe 'GET /api/benefits?title=' do
        before do
            create(:benefit, title: "Ruby Programming")
            create(:benefit, title: "JavaScript Essentials")
        end

        it 'filters benefits by title' do
            get "/api/benefits?api_token=#{token.token}", params: { title: 'ruby' }

            expect(response).to have_http_status(:ok)
            expect(json_response['benefits'].size).to eq(1)
            expect(json_response['benefits'][0]['title']).to match(/ruby/i)
        end
    end

    describe 'GET /api/benefits/recent' do
        before do
            create_list(:benefit, 5)
        end

        it 'returns most recent benefits' do
            get "/api/benefits/recent?api_token=#{token.token}"
            expect(response).to have_http_status(:ok)
            expect(json_response.size).to eq(5)
        end
    end

    describe 'GET /api/benefits/most_viewed' do
        before do
            create_list(:benefit, 5)
        end

        it 'returns most viewed benefits' do
            get "/api/benefits/most_viewed?api_token=#{token.token}"
            expect(response).to have_http_status(:ok)
            expect(json_response.size).to eq(5)
        end
    end

    private

    def json_response
        JSON.parse(response.body)
    end
end
