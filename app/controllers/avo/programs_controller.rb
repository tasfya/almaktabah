# This controller has been generated to enable Rails' resource routes.
# More information on https://docs.avohq.io/3.0/controllers.html
class Avo::ProgramsController < Avo::ResourcesController
  include AvoDestroyWithModelErrors

  private

  # Assigning domain_ids on a saved program writes at once, so the sites are
  # applied only once the program itself saved, in the same transaction.
  def save_record_action
    Program.transaction do
      super.tap do
        site_ids = @resource.submitted_site_ids
        @record.domain_ids = site_ids unless site_ids.nil?
      end
    end
  end
end
