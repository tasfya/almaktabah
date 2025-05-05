module Api
  module ErrorHandling
    extend ActiveSupport::Concern

    included do
      rescue_from ActiveRecord::RecordNotFound do |e|
        render_error(:not_found, e.message)
      end

      rescue_from ActionController::ParameterMissing do |e|
        render_error(:unprocessable_entity, e.message)
      end

      rescue_from ActiveRecord::RecordInvalid do |e|
        render_error(:unprocessable_entity, e.message)
      end
    end

    private

    def render_error(status, message)
      render json: {
        errors: [ { status: status, detail: message } ]
      }, status: status
    end
  end
end
