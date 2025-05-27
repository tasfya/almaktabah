require 'rails_helper'

class TestController < ActionController::Base
  include AdminAuthorization
  
  # Define our own root_path method since we don't have access to Rails routes in the test
  def root_path
    "/"
  end
  
  def index
    render plain: 'Admin area accessed', status: :ok
  end
end

RSpec.describe TestController, type: :controller do
  include Devise::Test::ControllerHelpers
  
  describe '#authenticate_admin!' do
    before do
      Rails.application.routes.draw do
        get 'index' => 'test#index'
      end
    end

    after do
      Rails.application.reload_routes!
    end

    context 'when user is not logged in' do
      it 'responds with forbidden status' do
        # Need to stub authenticate_user! since we're not actually using Devise in the test
        allow(controller).to receive(:authenticate_user!).and_return(true)
        allow(controller).to receive(:current_user).and_return(nil)
        
        get :index
        expect(response).to have_http_status(:forbidden)
        expect(flash[:alert]).to match(/must be an admin user/)
      end
    end

    context 'when user is logged in but not an admin' do
      before do
        @user = create(:user, admin: false)
        allow(controller).to receive(:authenticate_user!).and_return(true)
        allow(controller).to receive(:current_user).and_return(@user)
      end

      it 'responds with forbidden status for HTML requests' do
        get :index
        expect(response).to have_http_status(:forbidden)
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
        allow(controller).to receive(:authenticate_user!).and_return(true)
        allow(controller).to receive(:current_user).and_return(@admin)
      end

      it 'allows access to the controller action' do
        get :index
        expect(response).to have_http_status(:ok)
        expect(response.body).to eq('Admin area accessed')
      end
    end
  end
end
