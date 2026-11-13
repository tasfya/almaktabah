class Avo::Resources::Certificate < Avo::BaseResource
  self.title = :number
  self.includes = [ :domain, { enrollment: { cohort: :program } } ]
  self.search = {
    query: -> {
      term = "%#{ActiveRecord::Base.sanitize_sql_like(params[:q].to_s)}%"
      query.where("certificates.number LIKE :term OR certificates.full_name_snapshot LIKE :term", term: term)
    }
  }
  self.default_view_type = :table
  self.find_record_method = -> {
    id.is_a?(Array) ? query.where(number: id) : query.find_by!(number: id)
  }

  def authorization(user: nil)
    Avo::ReadOnlyAuthorization.new(user || Avo::Current.user, record || model_class)
  end

  def fields
    field :id, as: :id
    field :number, as: :text, name: "رقم الشهادة", sortable: true
    field :full_name_snapshot, as: :text, name: "الاسم"
    field :gender_snapshot, as: :text, name: "الجنس", hide_on: :index
    field :program_title, as: :text, name: "البرنامج" do
      record.enrollment&.cohort&.program&.title
    end
    field :cohort_name, as: :text, name: "الدفعة" do
      record.enrollment&.cohort&.name
    end
    field :issued_at, as: :date_time, name: "تاريخ الإصدار", sortable: true
    field :revoked_at, as: :date_time, name: "تاريخ الإلغاء", sortable: true
    field :enrollment, as: :belongs_to, name: "التسجيل", hide_on: :index
    field :domain, as: :belongs_to, name: "الموقع"
  end

  def actions
    action Avo::Actions::RevokeCertificate
  end
end
