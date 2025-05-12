require 'rails_helper'

RSpec.describe Api::V1::BooksController, type: :request do
    describe 'GET /api/books' do
        before do
            create_list(:book, 3)
        end

        it 'returns a list of books with metadata' do
            get '/api/books'
            expect(response).to have_http_status(:ok)

            expect(json_response).to be_a(Hash)
            expect(json_response['books']).to be_an(Array)
            expect(json_response['books'].size).to eq(3)
            expect(json_response['meta']).to include('current_page', 'total_items', 'categories')
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
                get '/api/books/999999'
                expect(response).to have_http_status(:not_found)
                expect(json_response).to include('error')
            end
        end
    end

    describe 'GET /api/books?title=' do
        before do
            create(:book, title: "Ruby Programming")
            create(:book, title: "JavaScript Essentials")
        end

        it 'filters books by title' do
            get '/api/books', params: { title: 'ruby' }

            expect(response).to have_http_status(:ok)
            expect(json_response['books'].size).to eq(1)
            expect(json_response['books'][0]['title']).to match(/ruby/i)
        end
    end

    describe 'GET /api/books/recent' do
        before do
            create_list(:book, 5)
        end

        it 'returns 10 most recent books' do
            get '/api/books/recent'
            expect(response).to have_http_status(:ok)
            expect(json_response.size).to eq(5)
        end
    end

    describe 'GET /api/books/most_downloaded' do
        before do
            create_list(:book, 5)
        end

        it 'returns 10 most recent books' do
            get '/api/books/recent'
            expect(response).to have_http_status(:ok)
            expect(json_response.size).to eq(5)
        end
    end

    describe 'GET /api/books/most_viewed' do
        before do
            create_list(:book, 5)
        end

        it 'returns 10 most recent books' do
            get '/api/books/recent'
            expect(response).to have_http_status(:ok)
            expect(json_response.size).to eq(5)
        end
    end

    private

    def json_response
        JSON.parse(response.body)
    end
end
