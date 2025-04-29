require 'rails_helper'

RSpec.describe Api::V1::UsersController, type: :request do
  describe 'POST /api/signup' do
    context 'with valid parameters' do
      let(:valid_params) do
        {
          user: {
            email: 'test@example.com',
            password: 'password123',
            password_confirmation: 'password123'
          }
        }
      end

      it 'creates a new user' do
        expect {
          post '/api/signup', params: valid_params
        }.to change(User, :count).by(1)
      end

      it 'returns a JWT token and user data' do
        post '/api/signup', params: valid_params

        expect(response).to have_http_status(:created)
        expect(json_response).to include('token', 'user')
        expect(json_response['user']['data']['attributes']['email']).to eq('test@example.com')
      end
    end

    context 'with invalid parameters' do
      let(:invalid_params) do
        {
          user: {
            email: 'invalid_email',
            password: 'pass',
            password_confirmation: 'different_password'
          }
        }
      end

      it 'does not create a new user' do
        expect {
          post '/api/signup', params: invalid_params
        }.not_to change(User, :count)
      end

      it 'returns unprocessable entity status with errors' do
        post '/api/signup', params: invalid_params

        expect(response).to have_http_status(:unprocessable_entity)
        expect(json_response).to include('errors')
        expect(json_response['errors']).to be_an(Array)
      end
    end
  end

  private

  def json_response
    JSON.parse(response.body)
  end
end
