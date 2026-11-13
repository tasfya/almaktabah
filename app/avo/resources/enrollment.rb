class Avo::Resources::Enrollment < Avo::BaseResource
  self.title = :id
  self.includes = [ :learner, :domain, :certificate, { cohort: :program } ]
  self.default_view_type = :table

  def authorization(user: nil)
    Avo::ReadOnlyAuthorization.new(user || Avo::Current.user, record || model_class)
  end

  def fields
    field :id, as: :id
    field :learner, as: :belongs_to
    field :cohort, as: :belongs_to
    field :program, as: :text do
      record.cohort.program.title
    end
    field :domain, as: :belongs_to, name: "Site"
    field :progress, as: :progress_bar, display_value: true, value_suffix: "%" do
      Programs::Progress.new(record).percent_complete
    end
    field :enrolled_at, as: :date_time, sortable: true
    field :completed_at, as: :date_time, hide_on: :index
    field :reminders_enabled, as: :boolean, hide_on: :index
    field :certificate_number, as: :text, name: "Certificate", as_html: true do
      certificate = record.certificate
      link_to(certificate.number, avo.resources_certificate_path(certificate)) if certificate
    end
  end
end
