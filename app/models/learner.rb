class Learner < ApplicationRecord
  devise :database_authenticatable, :registerable, :recoverable,
         :rememberable, :validatable, :confirmable

  enum :gender, { male: 0, female: 1 }

  has_many :enrollments, dependent: :destroy

  validates :full_name, :gender, presence: true

  before_create :skip_confirmation!, unless: -> { Rails.configuration.x.learner_mail_enabled }
end
