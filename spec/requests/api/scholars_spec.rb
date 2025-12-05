require 'openapi_helper'

xdescribe 'Scholars API', type: :request do
  let!(:scholar) { create(:scholar, :published) }

  path '/%D8%A7%D9%84%D8%B9%D9%84%D9%85%D8%A7%D8%A1' do
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
          expect(data.first).to have_key('full_name')
          expect(data.first).to have_key('full_name_alias')
        end
      end
    end
  end
end
