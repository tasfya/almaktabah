require "rails_helper"

RSpec.describe ReminderMailer do
  include_context "with learner mail on"

  before { stub_const("ENV", ENV.to_h.merge("LEARNER_MAIL_DOMAINS" => "3ilm.org,binramzan.net")) }

  let(:riyadh) { Time.find_zone("Asia/Riyadh") }
  let(:site) { create(:domain, host: "binramzan.net", title: "موقع الشيخ") }
  let(:program) { create(:program, title: "متون التوحيد") }
  let(:cohort) { create(:cohort, program: program, starts_on: Date.new(2025, 11, 8)) }
  let(:learner) { create(:learner, email: "fatima@example.com", full_name: "فاطمة بنت أحمد") }
  let(:enrollment) { create(:enrollment, cohort: cohort, learner: learner, domain: site) }
  let(:at) { riyadh.local(2025, 11, 19, 6, 5) }
  let(:lesson) { create(:program_item, :lesson, program: program, title_override: "الدرس الأول") }

  def mail
    described_class.daily(enrollment, Programs::ReminderDigest.new(enrollment, at: at))
  end

  def exam_closing_tonight
    item = create(:program_item, :exam, program: program, title_override: "الاختبار الأول")
    create(:question, exam: item.exam)
    create(:cohort_slot, cohort: cohort, program_item: item, available_on: Date.new(2025, 11, 17),
      opens_at: riyadh.local(2025, 11, 17), closes_at: riyadh.local(2025, 11, 19, 22))
  end

  before { create(:cohort_slot, cohort: cohort, program_item: lesson, available_on: Date.new(2025, 11, 19)) }

  it "is from the enrollment's site and links its cohort page" do
    expect(mail.to).to eq([ "fatima@example.com" ])
    expect(mail.from).to eq([ "no-reply@binramzan.net" ])
    expect(mail[:from].display_names).to eq([ "موقع الشيخ" ])
    expect(mail.subject).to eq("درس اليوم: متون التوحيد")
    expect(mail.html_part.body.to_s).to include("https://binramzan.net/my/cohorts/#{cohort.id}", "الدرس الأول", 'dir="rtl"')
    expect(mail.text_part.body.to_s).to include("https://binramzan.net/my/cohorts/#{cohort.id}", "الدرس الأول")
  end

  it "shows exam times in the cohort time zone, naming the zone" do
    exam_closing_tonight

    [ mail.text_part, mail.html_part ].each do |part|
      expect(part.body.to_s).to include("الاختبار الأول", "الأربعاء 19 نوفمبر، الساعة 10:00 م", "المواعيد بتوقيت مكة المكرمة")
    end
  end

  it "drops the hour of an exam opening at midnight" do
    item = create(:program_item, :exam, program: program, title_override: "اختبار القواعد")
    create(:question, exam: item.exam)
    create(:cohort_slot, cohort: cohort, program_item: item, available_on: Date.new(2025, 11, 19),
      opens_at: riyadh.local(2025, 11, 19), closes_at: riyadh.local(2025, 11, 21, 22))

    body = mail.text_part.body.to_s
    expect(body).to include("اختبار القواعد — يُفتح الأربعاء 19 نوفمبر")
    expect(body).not_to include("00:00")
  end

  it "addresses a female learner in the feminine" do
    learner.update!(gender: :female)

    expect(mail.html_part.body.to_s).to include("لأنك مسجّلة في هذا البرنامج")
    expect(mail.text_part.body.to_s).to include("لأنك مسجّلة في هذا البرنامج")
  end

  it "addresses a male learner in the masculine" do
    expect(mail.text_part.body.to_s).to include("لأنك مسجّل في هذا البرنامج")
  end

  it "says exam in the subject when there is no lesson today" do
    lesson.cohort_slots.delete_all
    exam_closing_tonight

    expect(mail.subject).to eq("تذكير بالاختبار: متون التوحيد")
  end

  it "carries one-click unsubscribe headers for the enrollment's site" do
    url = mail["List-Unsubscribe"].value[/\A<(.+)>\z/, 1]

    expect(mail["List-Unsubscribe-Post"].value).to eq("List-Unsubscribe=One-Click")
    expect(URI(url).host).to eq("binramzan.net")
    expect(URI(url).scheme).to eq("https")
    token = url.split("/").last
    expect(Enrollment.find_by_token_for(:reminders_off, token)).to eq(enrollment)
  end

  it "has footer links to turn reminders off and to the learner's programs" do
    url = mail["List-Unsubscribe"].value[/\A<(.+)>\z/, 1]

    expect(mail.html_part.body.to_s).to include(url, "https://binramzan.net/my")
    expect(mail.text_part.body.to_s).to include(url, "https://binramzan.net/my")
  end
end
