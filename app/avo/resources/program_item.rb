class Avo::Resources::ProgramItem < Avo::BaseResource
  self.title = :display_title
  self.includes = [ :lesson, :book, :exam ]
  self.visible_on_sidebar = false
  self.default_sort_column = :position
  self.default_sort_direction = :asc

  def fields
    field :id, as: :id, hide_on: :index
    field :program, as: :belongs_to, name: "البرنامج", disabled: -> { record&.persisted? }
    field :position, as: :number, name: "الترتيب", sortable: true, default: -> {
      program = ::Program.friendly.find(params[:via_record_id]) if params[:via_record_id].present?
      (program&.program_items&.maximum(:position) || 0) + 1
    }
    field :kind, as: :select, name: "النوع", enum: ::ProgramItem.kinds
    # Avo lists at most 1000 records in a belongs_to select, far fewer than the
    # library holds, so forms take the id (found through the Lessons/Books search).
    field :lesson, as: :belongs_to, name: "الدرس", only_on: :show
    field :lesson_id, as: :number, only_on: :forms, name: "رقم الدرس (ID)", help: "ابحث عن الدرس في Lessons وانسخ رقمه"
    field :book, as: :belongs_to, name: "الكتاب", only_on: :show
    field :book_id, as: :number, only_on: :forms, name: "رقم الكتاب (ID)", help: "ابحث عن الكتاب في Books وانسخ رقمه"
    field :exam, as: :belongs_to, name: "الاختبار", nullable: true, hide_on: :index,
      attach_scope: -> { parent.program_id ? query.where(program_id: parent.program_id) : query.none }
    field :display_title, as: :text, only_on: :index, name: "العنوان"
    field :title_override, as: :text, name: "عنوان بديل", hide_on: :index
    field :hidden, as: :boolean, name: "مخفي", help: "مخفي عن الطلاب (مثل تفريغ ينتظر الإذن)"
  end
end
