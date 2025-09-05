# frozen_string_literal: true

require 'rails_helper'

# Helper method for adding pagination headers to responses
def add_pagination_headers
  header 'Link', type: :string, description: 'RFC-8288 compliant pagination links (first, prev, next, last)'
  header 'Current-Page', type: :integer, description: 'Current page number'
  header 'Page-Items', type: :integer, description: 'Items per page'
  header 'Total-Pages', type: :integer, description: 'Total number of pages'
  header 'Total-Count', type: :integer, description: 'Total number of items'
end

RSpec.configure do |config|
  # Specify a root folder where Swagger JSON files are generated
  # NOTE: If you're using the rswag-api to serve API descriptions, you'll need
  # to ensure that it's configured to serve Swagger from the same folder
  config.openapi_root = Rails.root.join('swagger').to_s

  # Define one or more Swagger documents and provide global metadata for each one
  # When you run the 'rswag:specs:swaggerize' rake task, the complete Swagger will
  # be generated at the provided relative path under openapi_root
  # By default, the operations defined in spec files are added to the first
  # document below. You can override this behavior by adding a openapi_spec tag to the
  # the root example_group in your specs, e.g. describe '...', openapi_spec: 'v2/swagger.json'
  config.openapi_specs = {
    'v1/openapi.yaml' => {
      openapi: '3.0.1',
      info: {
        title: 'API V1',
        version: 'v1'
      },
      paths: {},
      servers: [
        {
          url: '{defaultHost}',
          variables: {
            defaultHost: {
              default: ''
            }
          }
        },
        {
          url: 'https://3ilm.org',
        },
      ],
      components: {
        schemas: {
          Scholar: {
            type: :object,
            properties: {
              id: { type: :integer },
              first_name: { type: :string },
              last_name: { type: :string },
              full_name: { type: :string },
              full_name_alias: { type: :string, nullable: true }
            },
            required: [:id, :first_name, :last_name, :full_name]
          },
          Book: {
            type: :object,
            properties: {
              id: { type: :integer },
              title: { type: :string },
              description: { type: :string, nullable: true },
              category: { type: :string, nullable: true },
              published_at: { type: :string, format: :date_time, nullable: true },
              downloads: { type: :integer },
              author: { '$ref' => '#/components/schemas/Scholar' },
              file_url: { type: :string, nullable: true },
              cover_image_url: { type: :string, nullable: true }
            },
            required: [:id, :title, :downloads, :author]
          },
          Lecture: {
            type: :object,
            properties: {
              id: { type: :integer },
              title: { type: :string },
              description: { type: :string, nullable: true },
              category: { type: :string, nullable: true },
              kind: { type: :string, enum: [:sermon, :conference, :benefit] },
              published_at: { type: :string, format: :date_time, nullable: true },
              duration: { type: :integer, nullable: true },
              scholar: { '$ref' => '#/components/schemas/Scholar' },
              thumbnail_url: { type: :string, nullable: true },
              audio_url: { type: :string, nullable: true },
              video_url: { type: :string, nullable: true }
            },
            required: [:id, :title, :kind, :scholar]
          },
          Series: {
            type: :object,
            properties: {
              id: { type: :integer },
              title: { type: :string },
              description: { type: :string, nullable: true },
              category: { type: :string, nullable: true },
              published: { type: :boolean },
              published_at: { type: :string, format: :date_time, nullable: true },
              scholar: { '$ref' => '#/components/schemas/Scholar', nullable: true },
              explainable_url: { type: :string, nullable: true },
              lessons_count: { type: :integer }
            },
            required: [:id, :title, :published, :lessons_count]
          },
          News: {
            type: :object,
            properties: {
              id: { type: :integer },
              title: { type: :string },
              description: { type: :string, nullable: true },
              slug: { type: :string },
              published_at: { type: :string, format: :date_time },
              content_excerpt: { type: :string },
              thumbnail_url: { type: :string, nullable: true }
            },
            required: [:id, :title, :slug, :published_at, :content_excerpt]
          },
          Article: {
            type: :object,
            properties: {
              id: { type: :integer },
              title: { type: :string },
              content: { type: :string, nullable: true },
              published_at: { type: :string, format: :date_time, nullable: true },
              author: { '$ref' => '#/components/schemas/Scholar' }
            },
            required: [:id, :title, :author]
          },
          Fatwa: {
            type: :object,
            properties: {
              id: { type: :integer },
              title: { type: :string },
              question: { type: :string, nullable: true },
              answer: { type: :string, nullable: true },
              category: { type: :string, nullable: true },
              published_at: { type: :string, format: :date_time, nullable: true },
              scholar: { '$ref' => '#/components/schemas/Scholar', nullable: true }
            },
            required: [:id, :title]
          },
          Error: {
            type: :object,
            properties: {
              error: { type: :string }
            },
            required: [:error]
          },
          PaginationMeta: {
            type: :object,
            properties: {
              count: { type: :integer },
              page: { type: :integer },
              prev: { type: :integer, nullable: true },
              next: { type: :integer, nullable: true },
              pages: { type: :integer },
              from: { type: :integer },
              to: { type: :integer }
            },
            required: [:count, :page, :pages, :from, :to]
          },
          BooksResponse: {
            type: :array,
            items: { '$ref' => '#/components/schemas/Book' }
          },
          LecturesResponse: {
            type: :array,
            items: { '$ref' => '#/components/schemas/Lecture' }
          },
          SeriesResponse: {
            type: :array,
            items: { '$ref' => '#/components/schemas/Series' }
          },
          NewsResponse: {
            type: :array,
            items: { '$ref' => '#/components/schemas/News' }
          },
          ArticlesResponse: {
            type: :array,
            items: { '$ref' => '#/components/schemas/Article' }
          },
          ScholarsResponse: {
            type: :array,
            items: { '$ref' => '#/components/schemas/Scholar' }
          },
          FatwasResponse: {
            type: :array,
            items: { '$ref' => '#/components/schemas/Fatwa' }
          },
        }
      }
    }
  }

  # Specify the format of the output Swagger file when running 'rswag:specs:swaggerize'.
  # The openapi_specs configuration option has the filename including format in
  # the key, this may want to be changed to avoid putting yaml in json files.
  # Defaults to json. Accepts ':json' and ':yaml'.
  config.openapi_format = :yaml
end
