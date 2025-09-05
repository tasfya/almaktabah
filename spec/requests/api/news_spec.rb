require 'openapi_helper'

describe 'News API', type: :request do
  let(:domain) { create(:domain, host: 'localhost') }
  let!(:news) { create(:news, :published) }

  before do
    # Assign news to domain
    news.assign_to(domain)
    news.save!

    # Set request host to match domain
    host! domain.host
  end

  path '/news' do
    get 'List news' do
      tags 'News'
      produces 'application/json'
      description 'Returns a paginated list of news for the current domain'

      parameter name: :page, in: :query, type: :integer, description: 'Page number'
      parameter name: :limit, in: :query, type: :integer, description: 'Items per page (max 100)'

      response '200', 'successful' do
        add_pagination_headers
        schema '$ref' => '#/components/schemas/NewsResponse'

        let(:page) { 1 }
        let(:limit) { 12 }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data).to be_an(Array)
          expect(data.first).to have_key('id')
          expect(data.first).to have_key('title')
          expect(data.first).to have_key('slug')
        end
      end
    end
  end
end
