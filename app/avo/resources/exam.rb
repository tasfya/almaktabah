class Avo::Resources::Exam < Avo::BaseResource
  self.title = :title
  self.includes = [ :program ]
  self.search = {
    query: -> { query.where("exams.title LIKE ?", "%#{ActiveRecord::Base.sanitize_sql_like(params[:q].to_s)}%") }
  }
  self.default_view_type = :table

  def fields
    field :id, as: :id
    field :program, as: :belongs_to, name: "البرنامج"
    field :title, as: :text, name: "العنوان", sortable: true
    field :no_questions_warning, as: :text, hide_on: :forms, name: "تنبيه", as_html: true,
      visible: -> { resource.view.index? || resource.record.questions.none? } do
      next if record.questions.any?

      if view.index?
        Avo::WarningMarkup.badge("بلا أسئلة", title: "لا يُفتح أبدًا")
      else
        Avo::WarningMarkup.alert("هذا الاختبار بلا أسئلة: لا يُفتح أبدًا، ولا يحصل أي طالب في دفعة يُجدول فيها على شهادة حتى تُكتب أسئلته.")
      end
    end
    field :description, as: :textarea, name: "الوصف"
    field :questions, as: :has_many, translation_key: "avo.resource_translations.question", attach_scope: -> { query.none }
  end
end
