# This controller has been generated to enable Rails' resource routes.
# More information on https://docs.avohq.io/3.0/controllers.html
class Avo::UsersController < Avo::ResourcesController
  def generate_api_token
    @user = User.find(params[:id])
    purpose = params[:purpose].presence || "API Access"

    token = @user.create_api_token(purpose: purpose)

    redirect_to avo.resources_user_path(@user), notice: "API token generated: #{token.token}"
  end
end
