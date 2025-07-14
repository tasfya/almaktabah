module Actionable
  extend ActiveSupport::Concern

  included do
    has_many :action_logs, as: :actionable, dependent: :destroy
  end

  def create_action_log(action)
    action_logs.create(action: action)
  end

  def has_action_log?(action)
    action_logs.exists?(action: action)
  end
end
