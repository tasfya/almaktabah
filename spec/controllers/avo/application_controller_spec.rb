require 'rails_helper'

RSpec.describe Avo::ApplicationController, type: :controller do
  controller do
    def index
      render plain: 'Avo dashboard accessed', status: :ok
    end
  end

  before do
    routes.draw do
      get 'index' => 'avo/application#index'
    end
  end

  describe 'authorization' do
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

      it 'redirects to root path with an alert' do
        get :index
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to match(/must be an admin user/)
      end
    end

    context 'when user is an admin' do
      before do
        @admin = create(:user, admin: true)
        sign_in @admin
      end

      it 'allows access to the dashboard' do
        get :index
        expect(response).to have_http_status(:ok)
        expect(response.body).to eq('Avo dashboard accessed')
      end
    end
  end
end
