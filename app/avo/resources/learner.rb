class Avo::Resources::Learner < Avo::BaseResource
  self.title = :full_name
  self.search = {
    query: -> {
      term = "%#{ActiveRecord::Base.sanitize_sql_like(params[:q].to_s)}%"
      query.where("learners.full_name LIKE :term OR learners.email LIKE :term", term: term)
    }
  }
  self.default_view_type = :table

  def authorization(user: nil)
    Avo::ReadOnlyAuthorization.new(user || Avo::Current.user, record || model_class)
  end

  def fields
    field :id, as: :id
    field :full_name, as: :text, sortable: true
    field :email, as: :text, sortable: true
    field :gender, as: :select, enum: ::Learner.genders
    field :confirmed_at, as: :date_time, hide_on: :index
    field :created_at, as: :date_time, sortable: true, name: "Signed up"
    field :enrollments, as: :has_many, attach_scope: -> { query.none }
  end

  def actions
    action Avo::Actions::ResetLearnerPassword
  end
end
