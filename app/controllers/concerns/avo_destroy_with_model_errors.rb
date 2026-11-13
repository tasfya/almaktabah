# Avo destroys with `destroy!` and appends the exception message ("Failed to
# destroy …") to the errors. Models that refuse deletion with their own
# message (restrict_with_error, before_destroy) should show only that message.
module AvoDestroyWithModelErrors
  private

  def destroy_record_action
    @record.destroy
  end
end
