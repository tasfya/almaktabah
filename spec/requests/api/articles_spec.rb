require 'openapi_helper'

describe 'Articles API', type: :request do
  let(:domain) { create(:domain, host: 'localhost') }
  let(:author) { create(:scholar) }
  let!(:article) { create(:article, :published, author: author) }

  before do
    # Assign article to domain
    article.assign_to(domain)
    article.save!

    # Set request host to match domain
    host! domain.host
  end

  path '/articles' do
    get 'List articles' do
      tags 'Articles'
      produces 'application/json'
      description 'Returns a paginated list of articles for the current domain'

      parameter name: :page, in: :query, type: :integer, description: 'Page number'
      parameter name: :limit, in: :query, type: :integer, description: 'Items per page (max 100)'

      response '200', 'successful' do
        add_pagination_headers
        schema '$ref' => '#/components/schemas/ArticlesResponse'

        let(:page) { 1 }
        let(:limit) { 12 }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data).to be_an(Array)
          expect(data.first).to have_key('id')
          expect(data.first).to have_key('title')
          expect(data.first).to have_key('content')
          expect(data.first).to have_key('published_at')
          expect(data.first).to have_key('author')
        end
      end
    end
  end
end
