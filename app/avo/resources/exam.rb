class Avo::Resources::Exam < Avo::BaseResource
  self.title = :title
  self.includes = [ :program ]
  self.search = {
    query: -> { query.where("exams.title LIKE ?", "%#{ActiveRecord::Base.sanitize_sql_like(params[:q].to_s)}%") }
  }
  self.default_view_type = :table

  def fields
    field :id, as: :id
    field :program, as: :belongs_to
    field :title, as: :text, sortable: true
    field :description, as: :textarea
    field :questions, as: :has_many
  end
end
