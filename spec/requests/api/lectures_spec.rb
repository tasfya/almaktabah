require 'openapi_helper'

describe 'Lectures API', type: :request do
  let(:domain) { create(:domain, host: 'localhost') }
  let(:scholar) { create(:scholar) }
  let!(:lecture) { create(:lecture, :published, :with_domain, scholar: scholar) }

  before do
    # Assign lecture to domain
    lecture.assign_to(domain)

    # Set request host to match domain
    host! domain.host
  end

  path '/lectures' do
    get 'List lectures' do
      tags 'Lectures'
      produces 'application/json'
      description 'Returns a paginated list of lectures for the current domain'


      parameter name: :page, in: :query, type: :integer, description: 'Page number'
      parameter name: :limit, in: :query, type: :integer, description: 'Items per page (max 100)'

      response '200', 'successful' do
        add_pagination_headers
        schema '$ref' => '#/components/schemas/LecturesResponse'

        let(:page) { 1 }
        let(:limit) { 12 }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data).to be_an(Array)
          expect(data.first).to have_key('id')
          expect(data.first).to have_key('title')
          expect(data.first).to have_key('scholar')
          expect(data.first).to have_key('kind')
        end
      end
    end
  end
end
