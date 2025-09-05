require 'openapi_helper'

describe 'Scholars API', type: :request do
  let!(:scholar) { create(:scholar, :published) }

  path '/scholars' do
    get 'List scholars' do
      tags 'Scholars'
      produces 'application/json'
      description 'Returns a paginated list of published scholars'

      parameter name: :page, in: :query, type: :integer, description: 'Page number'
      parameter name: :limit, in: :query, type: :integer, description: 'Items per page (max 100)'

      response '200', 'successful' do
        add_pagination_headers
        schema '$ref' => '#/components/schemas/ScholarsResponse'

        let(:page) { 1 }
        let(:limit) { 12 }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data).to be_an(Array)
          expect(data.first).to have_key('id')
          expect(data.first).to have_key('first_name')
          expect(data.first).to have_key('last_name')
        end
      end
    end
  end
end
