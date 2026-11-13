class Learner < ApplicationRecord
  devise :database_authenticatable, :registerable, :recoverable,
         :rememberable, :validatable, :confirmable

  enum :gender, { male: 0, female: 1 }, validate: true

  has_many :enrollments, dependent: :destroy

  normalizes :full_name, with: ->(name) { name.squish }

  validates :full_name, :gender, presence: true
  validates :full_name, length: { maximum: 100 }

  before_create :skip_confirmation!, unless: -> { Rails.configuration.x.learner_mail_enabled }
end
