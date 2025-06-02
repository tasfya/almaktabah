class ApiToken < ApplicationRecord
  belongs_to :user
  
  validates :token, presence: true, uniqueness: true
  validates :purpose, presence: true
  validates :user, presence: true
  
  before_validation :generate_token, on: :create
  before_create :set_defaults
  
  scope :active, -> { where(active: true).where("expires_at IS NULL OR expires_at > ?", Time.current) }
  
  def expired?
    expires_at.present? && expires_at < Time.current
  end
  
  def revoke
    update(active: false)
  end

  def display_name
    "#{purpose} (#{token[0..15]}...)"
  end
  
  private
  
  def generate_token
    self.token = loop do
      random_token = SecureRandom.hex(24)
      break random_token unless ApiToken.exists?(token: random_token)
    end
  end
  
  def set_defaults
    self.active = true if active.nil?
    self.expires_at = 1.year.from_now if expires_at.nil?
  end
end
