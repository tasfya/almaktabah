# frozen_string_literal: true

require "rails_helper"
require_relative "fixed_content"

# URLs that must answer 404, so search engines drop them instead of indexing an
# error page or a redirect.
RSpec.describe "URL contract: not found", type: :request do
  include_context "with fixed url contract content"

  describe "paths that used to route to controllers that never existed (#619)" do
    %w[/library /playlist/1 /category/1 /artist/1 /album/1].each do |path|
      it "answers 404 for #{path}" do
        get path
        expect(response).to have_http_status(:not_found)
      end
    end
  end
end
