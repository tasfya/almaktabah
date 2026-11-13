class Avo::Resources::ProgramItem < Avo::BaseResource
  self.title = :display_title
  self.includes = [ :lesson, :book, :exam ]
  self.visible_on_sidebar = false
  self.default_sort_column = :position
  self.default_sort_direction = :asc

  def fields
    field :id, as: :id, hide_on: :index
    field :program, as: :belongs_to
    field :position, as: :number, sortable: true, default: -> {
      program = ::Program.friendly.find(params[:via_record_id]) if params[:via_record_id].present?
      (program&.program_items&.maximum(:position) || 0) + 1
    }
    field :kind, as: :select, enum: ::ProgramItem.kinds
    field :lesson, as: :belongs_to, searchable: true, nullable: true
    field :book, as: :belongs_to, searchable: true, nullable: true
    field :exam, as: :belongs_to, nullable: true,
      attach_scope: -> { parent.program_id ? query.where(program_id: parent.program_id) : query.none }
    field :display_title, as: :text, only_on: :index, name: "Title"
    field :title_override, as: :text, hide_on: :index
    field :hidden, as: :boolean, help: "Hidden from learners (e.g. transcripts awaiting permission)"
  end
end
