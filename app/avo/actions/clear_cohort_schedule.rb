class Avo::Actions::ClearCohortSchedule < Avo::BaseAction
  self.name = "Clear schedule"
  self.message = "Deletes every slot of the cohort. Refused once a learner has ticked a lesson or taken an exam."

  def handle(records:, **)
    refused = records.reject(&:clear_schedule!)
    return succeed("Schedule cleared") if refused.empty?

    error refused.map { |cohort| "#{cohort.name}: #{cohort.errors.full_messages.to_sentence}" }.join("\n")
    keep_modal_open
  end
end
