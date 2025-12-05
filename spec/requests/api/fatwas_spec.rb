require 'openapi_helper'

xdescribe 'Fatwas API', type: :request do
  let(:domain) { create(:domain, host: 'localhost') }
  let!(:fatwa) { create(:fatwa, :published) }

  before do
    # Assign fatwa to domain
    fatwa.assign_to(domain)

    # Set request host to match domain
    host! domain.host
  end

  path '/%D8%A7%D9%84%D9%81%D8%AA%D8%A7%D9%88%D9%89' do
    get 'List fatwas' do
      tags 'Fatwas'
      produces 'application/json'
      description 'Returns a paginated list of fatwas for the current domain'

      parameter name: :page, in: :query, type: :integer, description: 'Page number'
      parameter name: :limit, in: :query, type: :integer, description: 'Items per page (max 100)'

      response '200', 'successful' do
        add_pagination_headers
        schema '$ref' => '#/components/schemas/FatwasResponse'

        let(:page) { 1 }
        let(:limit) { 12 }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data).to be_an(Array)
          fatwa_data = data.first
          expect(fatwa_data).to have_key('id')
          expect(fatwa_data).to have_key('title')
          expect(fatwa_data).to have_key('question')
          expect(fatwa_data).to have_key('answer')
          expect(fatwa_data).to have_key('category')
          expect(fatwa_data).to have_key('published_at')
          expect(fatwa_data).to have_key('scholar')
        end
      end
    end
  end
end
