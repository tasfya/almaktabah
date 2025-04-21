class Tenant < ApplicationRecord
  has_one_attached :logo_light
  has_one_attached :logo_dark
end
