# frozen_string_literal: true

# The app picks its tenant from the request host (Domain.find_by_host), so a
# request spec needs a Domain row for the host it sends requests to.
module TenantHelpers
  # Creates the Domain for +host+ and sends the following requests to it.
  #
  #   let!(:domain) { with_domain("localhost") }
  def with_domain(host = "localhost", **attributes)
    create(:domain, host: host, **attributes).tap { host!(host) }
  end
end

# Provides `domain` (served at `tenant_host`) and `other_domain` (a second
# tenant whose content must not leak). Override either `let` to change them:
#
#   include_context "with tenant domain"
#   let(:tenant_host) { "www.example.com" }
#   let(:tenant_domain_attributes) { { name: "Test Site" } }
RSpec.shared_context "with tenant domain" do
  let(:tenant_host) { "localhost" }
  let(:tenant_domain_attributes) { {} }
  let!(:domain) { with_domain(tenant_host, **tenant_domain_attributes) }
  let(:other_domain) { create(:domain, host: "other.example.com") }
end

RSpec.configure do |config|
  config.include TenantHelpers, type: :request
end
