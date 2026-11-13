# Maps a source item (a Telegram message, or a key such as "series:qawaid") to
# the record an import created or linked, so a re-run finds it instead of
# creating it again.
class TelegramImportRecord < ApplicationRecord
  OUTCOMES = %w[created linked].freeze

  belongs_to :record, polymorphic: true

  validates :source, :external_id, presence: true
  validates :outcome, inclusion: { in: OUTCOMES }

  scope :created_records, -> { where(outcome: "created") }

  def self.lookup(source, external_id)
    find_by(source: source, external_id: external_id)&.record
  end

  def created?
    outcome == "created"
  end
end
