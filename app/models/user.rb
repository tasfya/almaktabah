class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  # Note: :registerable is intentionally excluded to disable user signup
  devise :database_authenticatable,
         :recoverable, :rememberable, :validatable

  has_many :user_scholars, dependent: :destroy
  has_many :scholars, through: :user_scholars

  scope :admins, -> { where(admin: true) }

  def admin?
    admin
  end
end
