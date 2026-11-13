class ProgramItem < ApplicationRecord
  REFERENCES = %i[lesson book exam].freeze

  belongs_to :program, inverse_of: :program_items
  belongs_to :lesson, optional: true
  belongs_to :book, optional: true

  enum :kind, { lesson: 0, book: 1, exam: 2 }

  validates :kind, presence: true
  validates :position, presence: true, uniqueness: { scope: :program_id }
  validate :reference_matches_kind

  def display_title
    title_override.presence || (respond_to?(kind) ? public_send(kind)&.title : nil)
  end

  private

  def reference_matches_kind
    REFERENCES.each do |reference|
      present = respond_to?(reference) ? public_send(reference).present? : self[:"#{reference}_id"].present?
      if reference.to_s == kind
        errors.add(reference, :blank) unless present
      elsif present
        errors.add(:"#{reference}_id", :present)
      end
    end
  end
end
