require 'rails_helper'

RSpec.describe Api::V1::BooksController, type: :request do
    describe 'GET /api/books' do
        before do
            create_list(:book, 3)
        end

        it 'returns a list of books' do
            get '/api/books'
            expect(response).to have_http_status(:ok)
            expect(json_response).to be_an(Array)
            expect(json_response.size).to eq(3)
        end
    end

    describe 'GET /api/books/:id' do
        let(:book) { create(:book) }

        context 'when the book exists' do
            it 'returns the requested book' do
                get "/api/books/#{book.id}"

                expect(response).to have_http_status(:ok)
                expect(json_response['id']).to eq(book.id)
            end
        end

        context 'when the book does not exist' do
            it 'returns a not found error' do
                get '/api/books/999'

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
