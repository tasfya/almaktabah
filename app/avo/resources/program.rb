class Avo::Resources::Program < Avo::BaseResource
  self.title = :title
  self.includes = [ :domains ]
  self.search = {
    query: -> { query.where("programs.title LIKE ?", "%#{ActiveRecord::Base.sanitize_sql_like(params[:q].to_s)}%") }
  }
  self.default_view_type = :table

  def fields
    field :id, as: :id
    field :title, as: :text, sortable: true
    field :slug, as: :text, only_on: :show
    field :description, as: :textarea
    field :published, as: :boolean, sortable: true
    field :published_at, as: :date_time, hide_on: :index
    field :pass_mark, as: :number, min: 0, max: 100, help: "Minimum exam score (%) for a certificate"
    field :sites, as: :boolean_group, only_on: :forms,
      options: -> { ::Domain.order(:name).pluck(:id, :name).to_h { |id, name| [ id.to_s, name ] } },
      format_using: -> { record.domain_ids.to_h { |id| [ id.to_s, true ] } },
      help: "The sites that list and serve this program"
    field :site_names, as: :text, name: "Sites", only_on: :show do
      record.domains.map(&:name).to_sentence
    end
    field :program_items, as: :has_many, name: "Items", attach_scope: -> { query.none }
    field :exams, as: :has_many, attach_scope: -> { query.none }
    field :cohorts, as: :has_many, attach_scope: -> { query.none }
  end

  # Site ids submitted by the form, or nil when it sent none. The checkboxes
  # are not a Program attribute, so they are taken out of the params here and
  # the controller applies them after the program saves.
  attr_reader :submitted_site_ids

  def hydrate(**args)
    Avo::FormOnlyFields.define_on(args[:record], [ :sites ])
    super
  end

  def fill_record(record, permitted_params, **)
    sites = permitted_params.delete(:sites)
    @submitted_site_ids = Array(sites).compact_blank.map(&:to_i) unless sites.nil?
    super
  end
end
