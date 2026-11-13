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
    field :full_name, as: :text, name: "الاسم الكامل", sortable: true
    field :email, as: :text, name: "البريد الإلكتروني", sortable: true
    field :gender, as: :select, name: "الجنس", enum: ::Learner.genders
    field :confirmed_at, as: :date_time, name: "تأكيد البريد", hide_on: :index
    field :created_at, as: :date_time, sortable: true, name: "تاريخ التسجيل"
    field :enrollments, as: :has_many, translation_key: "avo.resource_translations.enrollment", attach_scope: -> { query.none }
  end

  def actions
    action Avo::Actions::ResetLearnerPassword
  end
end
