# frozen_string_literal: true

require "rails_helper"

# The search services build filter_by / facet_by / sort_by / query_by strings
# against field names, and Typesense rejects a query that filters or facets on
# a field missing from the schema (or not declared facet). These examples read
# the schema Typesense actually built from each model's `typesense` block and
# check every field the services depend on.
RSpec.describe "Typesense schema contract", :typesense do
  def schema_fields(collection)
    TypesenseSearch::Client.instance.collections[collection].retrieve["fields"].index_by { |f| f["name"] }
  end

  # TypesenseSearch::FilterBuilder#domain_filter and DomainContentTypesService.
  domain_filter_field = "domain_ids"
  # TypesenseSearch::FilterBuilder#scholars_filter and the disjunctive facet queries.
  scholar_field = "scholar_name"
  # DomainContentTypesService facets on it; MixedSearchService reads it per hit.
  content_type_field = "content_type"
  # sort_order / common_params in the collection, browse and mixed services.
  sort_field = "created_at_ts"

  it "covers every collection the services query" do
    expect(TypesenseIntegration::MODELS.map(&:name)).to match_array(TypesenseSearch::Collections::NAMES)
  end

  TypesenseSearch::Collections::NAMES.each do |collection|
    describe collection do
      subject(:fields) { schema_fields(collection) }

      it "has every query_by field as a string" do
        TypesenseSearch::Collections::SEARCHABLE_FIELDS.fetch(collection).split(",").each do |name|
          expect(fields[name]).to include("type" => "string"), "#{collection}.#{name} must be an indexed string (query_by)"
        end
      end

      it "has every facet_by field declared as a facet" do
        facet_fields = TypesenseSearch::Collections::FACET_FIELDS.split(",") | [ scholar_field, content_type_field ]

        facet_fields.each do |name|
          expect(fields[name]).to include("type" => "string", "facet" => true), "#{collection}.#{name} must be a string facet (facet_by)"
        end
      end

      it "has domain_ids as a facetable int32[] for the domain filter" do
        expect(fields[domain_filter_field]).to include("type" => "int32[]", "facet" => true)
      end

      it "has a required, sortable int64 created_at_ts for newest-first ordering" do
        expect(fields[sort_field]).to include("type" => "int64", "sort" => true)
        expect(fields[sort_field]["optional"]).to be_falsey
      end

      it "has published_at_ts as an optional int64" do
        expect(fields["published_at_ts"]).to include("type" => "int64", "optional" => true)
      end

      it "has the url and slug strings the result views link with" do
        expect(fields["url"]).to include("type" => "string")
        expect(fields["slug"]).to include("type" => "string")
      end
    end
  end
end
