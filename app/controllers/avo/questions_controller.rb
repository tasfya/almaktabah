# This controller has been generated to enable Rails' resource routes.
# More information on https://docs.avohq.io/3.0/controllers.html
class Avo::QuestionsController < Avo::ResourcesController
  include AvoDestroyWithModelErrors

  private

  # Rails swallows an answered choice's refusal in the choices cascade, so the
  # question would fail to delete without saying why.
  def destroy_record_action
    if @record.attempt_answers.exists?
      @record.errors.add(:base, :"restrict_dependent_destroy.has_many", record: Question.human_attribute_name(:attempt_answers))
      return false
    end

    super
  end

  # Removing a choice a learner already answered fails inside the autosave
  # with the choice's own message; show that instead of "Failed to destroy".
  def save_record_action
    super
  rescue ActiveRecord::RecordNotDestroyed => e
    e.record.errors.full_messages.each { |message| @record.errors.add(:base, message) }
    false
  end
end
