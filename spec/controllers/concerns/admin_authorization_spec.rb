require 'rails_helper'

RSpec.describe AdminAuthorization, type: :concern do
  # Create a test controller that includes our concern
  controller(ActionController::Base) do
    include AdminAuthorization
    
    def index
      render plain: 'Admin area accessed', status: :ok
    end
  end

  # Set up routes for our test controller
  before do
    routes.draw do
      get 'index' => 'anonymous#index'
    end
  end

  describe '#authenticate_admin!' do
    context 'when user is not logged in' do
      it 'redirects to sign in page' do
        get :index
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context 'when user is logged in but not an admin' do
      before do
        @user = create(:user, admin: false)
        sign_in @user
      end

      it 'redirects to root path' do
        get :index
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to match(/must be an admin user/)
      end

      it 'responds with forbidden status for JSON requests' do
        request.accept = 'application/json'
        get :index
        expect(response).to have_http_status(:forbidden)
        expect(JSON.parse(response.body)).to have_key('error')
      end
    end

    context 'when user is an admin' do
      before do
        @admin = create(:user, admin: true)
        sign_in @admin
      end

      it 'allows access to the controller action' do
        get :index
        expect(response).to have_http_status(:ok)
        expect(response.body).to eq('Admin area accessed')
      end
    end
  end
end
