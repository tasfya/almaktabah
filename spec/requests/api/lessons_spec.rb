require 'openapi_helper'

xdescribe 'Lessons API', type: :request do
  let(:domain) { create(:domain, host: 'localhost') }
  let(:scholar) { create(:scholar) }
  let(:series) { create(:series, :published, scholar: scholar) }
  let!(:lesson) { create(:lesson, :published, series: series) }

  before do
    # Assign lesson to domain via series
    series.assign_to(domain)

    # Set request host to match domain
    host! domain.host
  end

  path '/lessons' do
    get 'List lessons' do
      tags 'Lessons'
      produces 'application/json'
      description 'Returns a paginated list of lessons for the current domain'

      parameter name: :page, in: :query, type: :integer, description: 'Page number'
      parameter name: :limit, in: :query, type: :integer, description: 'Items per page (max 100)'

      response '200', 'successful' do
        add_pagination_headers
        schema '$ref' => '#/components/schemas/LessonsResponse'

        let(:page) { 1 }
        let(:limit) { 12 }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data).to be_an(Array)
          lesson_data = data.first
          expect(lesson_data).to have_key('id')
          expect(lesson_data).to have_key('title')
          expect(lesson_data).to have_key('description')
          expect(lesson_data).to have_key('position')
          expect(lesson_data).to have_key('published_at')
          expect(lesson_data).to have_key('duration')
          expect(lesson_data).to have_key('series_id')
          expect(lesson_data).to have_key('scholar')
          expect(lesson_data).to have_key('thumbnail_url')
          expect(lesson_data).to have_key('audio_url')
          expect(lesson_data).to have_key('video_url')
        end
      end
    end
  end
end
