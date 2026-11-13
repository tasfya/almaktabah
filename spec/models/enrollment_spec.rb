require "rails_helper"

RSpec.describe Enrollment, type: :model do
  it "does not let a learner enroll twice" do
    enrollment = create(:enrollment)
    duplicate = build(:enrollment, learner: enrollment.learner, cohort: enrollment.cohort)

    expect(duplicate).not_to be_valid
    expect { duplicate.save!(validate: false) }.to raise_error(ActiveRecord::RecordNotUnique)
  end

  it "defaults to reminders on and enrolled now" do
    enrollment = create(:enrollment, enrolled_at: nil)
    expect(enrollment.reminders_enabled).to be(true)
    expect(enrollment.enrolled_at).to be_within(1.minute).of(Time.current)
  end

  it "is destroyed with its learner, taking its completions" do
    completion = create(:lesson_completion)
    completion.enrollment.learner.destroy!

    expect(Enrollment.count).to eq(0)
    expect(LessonCompletion.count).to eq(0)
  end

  it "keeps a cohort with enrollments from being destroyed" do
    enrollment = create(:enrollment)
    expect(enrollment.cohort.destroy).to be(false)
    expect(enrollment.cohort.errors).to be_present
  end

  it "keeps a ticked program item from being destroyed" do
    completion = create(:lesson_completion)
    expect(completion.program_item.destroy).to be(false)
  end
end
