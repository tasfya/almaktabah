class PlayController < ApplicationController
  before_action :set_resource, only: [:show]

  def show
    render 'play/show', locals: { resource: @resource }
  end

  def stop
    render turbo_stream: turbo_stream.update("audio", "")
  end

  private

  def set_resource
    resource_type = params[:resource_type].classify
    resource_class = resource_type.constantize
    @resource = resource_class.for_domain_id(@domain.id).published.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to root_path, alert: t("messages.#{params[:resource_type]}_not_found")
  rescue NameError
    redirect_to root_path, alert: t("messages.invalid_resource")
  end
end