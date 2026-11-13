class Avo::Resources::Question < Avo::BaseResource
  CHOICE_SLOTS = 5
  TRUE_FALSE_BODIES = [ "صح", "خطأ" ].freeze
  FORM_ONLY_FIELDS = [ *Array.new(CHOICE_SLOTS) { |index| :"choice_#{index + 1}" }, :correct_slot ].freeze

  self.title = :body
  self.includes = [ :choices ]
  self.visible_on_sidebar = false
  self.default_sort_column = :position
  self.default_sort_direction = :asc

  def fields
    field :id, as: :id, hide_on: :index
    field :exam, as: :belongs_to
    field :position, as: :number, sortable: true, default: -> {
      exam = ::Exam.find_by(id: params[:via_record_id]) if params[:via_record_id].present?
      (exam&.questions&.maximum(:position) || 0) + 1
    }
    field :kind, as: :select, enum: ::Question.kinds
    field :body, as: :textarea, show_on: :index
    field :choices, as: :text, only_on: %i[index show], as_html: true do
      record.choices.map { |choice| ERB::Util.h("#{choice.correct? ? "✓" : "·"} #{choice.body}") }.join("<br>").html_safe
    end

    CHOICE_SLOTS.times do |index|
      field :"choice_#{index + 1}", as: :text, only_on: :forms, name: "Choice #{index + 1}",
        format_using: -> { record.choices[index]&.body },
        help: index.zero? ? "Leave blank to remove a choice. True/false questions default to #{TRUE_FALSE_BODIES.join(" / ")}." : nil
    end
    field :correct_slot, as: :select, only_on: :forms, name: "Correct choice",
      options: (1..CHOICE_SLOTS).to_h { |n| [ "Choice #{n}", n.to_s ] },
      include_blank: true,
      format_using: -> { (record.choices.index(&:correct?)&.+(1))&.to_s }
  end

  # Choices are edited in the question's own form so the question validates
  # them together (exactly one correct, two for true/false) in one save. The
  # slots are not Question attributes, so they are taken out before Avo fills
  # the record and applied to the loaded choices in memory.
  def hydrate(**args)
    Avo::FormOnlyFields.define_on(args[:record], FORM_ONLY_FIELDS)
    super
  end

  def fill_record(record, permitted_params, **)
    slots = Array.new(CHOICE_SLOTS) { |index| permitted_params.delete(:"choice_#{index + 1}") }
    correct = permitted_params.delete(:correct_slot)
    super.tap { |question| apply_choices(question, slots, correct.to_i) unless slots.all?(&:nil?) }
  end

  private

  def apply_choices(question, slots, correct)
    bodies = slots.map { |body| body.to_s.strip }
    TRUE_FALSE_BODIES.each_with_index { |body, index| bodies[index] = bodies[index].presence || body } if question.true_false?

    existing = question.choices.to_a
    next_position = existing.map(&:position).max || 0
    bodies.each_with_index do |body, index|
      choice = existing[index]
      if body.blank?
        choice&.mark_for_destruction
      else
        choice ||= question.choices.build(position: next_position += 1)
        choice.assign_attributes(body: body, correct: index + 1 == correct)
      end
    end
  end
end
