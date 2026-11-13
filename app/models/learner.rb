class Learner < ApplicationRecord
  devise :database_authenticatable, :registerable, :recoverable,
         :rememberable, :validatable, :confirmable

  enum :gender, { male: 0, female: 1 }, validate: true

  belongs_to :domain, optional: true
  has_many :enrollments, dependent: :destroy

  normalizes :full_name, with: ->(name) { name.squish }

  validates :full_name, :gender, presence: true
  validates :full_name, length: { maximum: 100 }

  before_create :skip_confirmation!, unless: -> { Rails.configuration.x.learner_mail_enabled }

  def devise_mailer
    Learners::Mailer
  end

  protected

  # Mail goes out on behalf of the site the request came from, or the site the
  # learner signed up on when there is no request (console, jobs).
  def send_devise_notification(notification, *args)
    opts = args.extract_options!
    opts[:domain_id] ||= (Current.domain || domain)&.id
    # Development hosts (portless, 127.0.0.1:<port>) are not the Domain's host.
    opts[:url_options] ||= Current.request_url_options if Rails.env.development?
    devise_mailer.send(notification, self, *args, opts).deliver_later
  end
end
