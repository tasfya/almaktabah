module Api
  module V1
    class ContactsController < ApiController
      skip_before_action :authenticate_request, only: [ :create ]
      skip_before_action :verify_authenticity_token, only: [ :create ]
      # POST /api/contacts
      def create
        @contact = Contact.new(contact_params)

        if @contact.save
          render json: @contact, status: :created
        else
          render json: { errors: @contact.errors }, status: :unprocessable_entity
        end
      end

      private

      def contact_params
        params.require(:contact).permit(:name, :email, :subject, :message)
      end
    end
  end
end
