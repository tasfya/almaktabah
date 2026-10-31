require "rails_helper"

RSpec.describe "config/recurring.yml" do
  let(:tasks) { YAML.load_file(Rails.root.join("config/recurring.yml")).fetch("production") }

  describe "clear_solid_queue_finished_jobs" do
    let(:task) { tasks.fetch("clear_solid_queue_finished_jobs") }

    def create_job(**attrs)
      SolidQueue::Job.create!(class_name: "SomeJob", queue_name: "default", **attrs)
    end

    after { SolidQueue::Job.delete_all }

    it "deletes only jobs finished before the retention window" do
      old_finished = create_job(finished_at: 2.days.ago)
      recent_finished = create_job(finished_at: 1.hour.ago)
      failed = create_job
      SolidQueue::FailedExecution.create!(job: failed, error: "boom")
      scheduled = create_job(scheduled_at: 1.day.from_now)

      eval(task.fetch("command")) # rubocop:disable Security/Eval

      remaining = SolidQueue::Job.where(id: [ old_finished, recent_finished, failed, scheduled ].map(&:id))
      expect(remaining).to contain_exactly(recent_finished, failed, scheduled)
      expect(SolidQueue::FailedExecution.where(job_id: failed.id)).to exist
    end
  end
end
