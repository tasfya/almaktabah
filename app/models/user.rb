class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  has_many :api_tokens, dependent: :destroy
         
  scope :admins, -> { where(admin: true) }

  def admin?
    admin
  end
  
  def active_api_tokens
    api_tokens.active
  end
  
  def create_api_token(purpose: 'API Access', expires_at: nil, rate_limit: 100)
    api_tokens.create!(
      purpose: purpose, 
      expires_at: expires_at, 
    )
  end
end
