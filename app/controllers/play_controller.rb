class PlayController < ApplicationController
  before_action :set_resource, only: [ :show ]

  def show
    render "play/show", locals: { resource: @resource }
  end

  def stop
    render turbo_stream: turbo_stream.update("audio", "")
  end

  private

  def set_resource
    resource_type = params[:resource_type].classify
    resource_class = resource_class(resource_type)
    @resource = resource_class.for_domain_id(@domain.id).published.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to root_path, alert: t("messages.#{params[:resource_type]}_not_found")
  rescue NameError
    redirect_to root_path, alert: t("messages.invalid_resource")
  end

  def resource_class(resource_type)
    valid_resource_types = %w[Lesson Lecture Benefit]
    if valid_resource_types.include?(resource_type)
      resource_type.constantize
    else
      raise NameError, "Invalid resource type: #{resource_type}"
    end
  end
end
