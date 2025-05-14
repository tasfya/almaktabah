require 'rails_helper'

RSpec.describe Api::V1::AuthenticationController, type: :request do
  describe 'POST /api/login' do
    let(:user) { create(:user) }

    context 'with valid credentials' do
      let(:valid_params) do
        {
          user: {
            email: user.email,
            password: 'password123'
          }
        }
      end

      it 'returns a JWT token' do
        post '/api/login', params: valid_params

        expect(response).to have_http_status(:ok)
        expect(json_response).to include('token', 'user')
        expect(json_response['user']['email']).to eq(user.email)
      end
    end

    context 'with invalid credentials' do
      let(:invalid_params) do
        {
          user: {
            email: user.email,
            password: 'wrong_password'
          }
        }
      end

      it 'returns unauthorized status' do
        post '/api/login', params: invalid_params

        expect(response).to have_http_status(:unauthorized)
        expect(json_response['error']).to eq('Invalid email or password')
      end
    end
  end

  private

  def json_response
    JSON.parse(response.body)
  end
end
