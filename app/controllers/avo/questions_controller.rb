# This controller has been generated to enable Rails' resource routes.
# More information on https://docs.avohq.io/3.0/controllers.html
class Avo::QuestionsController < Avo::ResourcesController
  include AvoDestroyWithModelErrors

  private

  # Removing a choice a learner already answered fails inside the autosave
  # with the choice's own message; show that instead of "Failed to destroy".
  def save_record_action
    super
  rescue ActiveRecord::RecordNotDestroyed => e
    e.record.errors.full_messages.each { |message| @record.errors.add(:base, message) }
    false
  end
end
