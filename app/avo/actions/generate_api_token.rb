module Avo
  module Actions
    class GenerateApiToken < Avo::BaseAction
      self.name = "Generate API Token"
      self.no_confirmation = false
      self.standalone = true
      self.visible = -> do
        view == :show
      end

      def fields
        field :purpose, as: :text, default: "API Access", help: "What this token will be used for", required: true
        field :expires_at, as: :date_time, help: "When this token should expire (leave blank for 1 year)", required: false
      end

      def handle(**args)
        purpose = args[:purpose]
        expires_at = args[:expires_at]

        @record.create_api_token(
          purpose: purpose,
          expires_at: expires_at
        )

        succeed "API token generated successfully"
      end
    end
  end
end
