# One row per enrollment and cohort-local day: claimed before the reminder is
# sent, so the unique index lets at most one mail go out per day.
class ReminderDelivery < ApplicationRecord
  belongs_to :enrollment
end
