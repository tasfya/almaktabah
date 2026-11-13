class Current < ActiveSupport::CurrentAttributes
  attribute :domain, :request_url_options
end
