require 'openapi_helper'

describe 'Series API', type: :request do
  let(:domain) { create(:domain, host: 'localhost') }
  let(:scholar) { create(:scholar) }
  let!(:series) { create(:series, :published, scholar: scholar) }

  before do
    # Assign series to domain
    series.assign_to(domain)
    series.save!

    # Set request host to match domain
    host! domain.host
  end

  path '/series' do
    get 'List series' do
      tags 'Series'
      produces 'application/json'
      description 'Returns a paginated list of series for the current domain'

      parameter name: :page, in: :query, type: :integer, description: 'Page number'
      parameter name: :limit, in: :query, type: :integer, description: 'Items per page (max 100)'

      response '200', 'successful' do
        add_pagination_headers
        schema '$ref' => '#/components/schemas/SeriesResponse'

        let(:page) { 1 }
        let(:limit) { 12 }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data).to be_an(Array)
          expect(data.first).to have_key('id')
          expect(data.first).to have_key('title')
          expect(data.first).to have_key('scholar')
        end
      end
    end
  end
end
