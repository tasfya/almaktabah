class HomeController < ApplicationController
  def index
    render json: { message: "Welcome to Almaktabah API" }
  end
end
