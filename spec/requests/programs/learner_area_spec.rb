require "rails_helper"

RSpec.describe "Learner area", type: :request do
  include Devise::Test::IntegrationHelpers
  include ActiveSupport::Testing::TimeHelpers

  include_context "with tenant domain"

  let(:riyadh) { Time.find_zone("Asia/Riyadh") }
  let(:learner) { create(:learner) }
  let(:program) { create(:program, published: true).tap { |p| p.update!(domains: [ domain ]) } }
  let(:cohort) { create(:cohort, program: program, starts_on: Date.new(2025, 11, 8)) }
  let!(:enrollment) { create(:enrollment, learner: learner, cohort: cohort, domain: domain) }
  let(:turbo_stream) { { "Accept" => "text/vnd.turbo-stream.html" } }

  def scheduled(kind, position:, on:, **attributes)
    item = create(:program_item, kind, program: program, position: position, **attributes)
    create(:cohort_slot, cohort: cohort, program_item: item, available_on: on)
    item
  end

  def scheduled_exam(position:, exam: create(:exam, :with_questions, program: program))
    item = create(:program_item, :exam, program: program, position: position, exam: exam)
    create(:cohort_slot, cohort: cohort, program_item: item, available_on: Date.new(2025, 11, 19),
                         opens_at: riyadh.local(2025, 11, 19), closes_at: riyadh.local(2025, 11, 21, 22))
    item
  end

  def tick(item, headers: turbo_stream)
    post learner_cohort_completions_path(cohort), params: { program_item_id: item.id }, headers: headers
  end

  let!(:first_lesson) { scheduled(:lesson, position: 1, on: Date.new(2025, 11, 8), lesson: create(:lesson, title: "شرح القواعد الأربع ١")) }
  let!(:matn) { scheduled(:book, position: 2, on: Date.new(2025, 11, 8), book: create(:book, title: "متن القواعد الأربع")) }
  let!(:second_lesson) { scheduled(:lesson, position: 3, on: Date.new(2025, 11, 9)) }
  let!(:exam) { scheduled_exam(position: 4) }
  let!(:future_lesson) { scheduled(:lesson, position: 5, on: Date.new(2025, 11, 25)) }

  around { |example| travel_to(riyadh.local(2025, 11, 9, 10)) { example.run } }

  describe "authentication" do
    it "requires a signed-in learner, without a publicly cacheable redirect" do
      [ learner_dashboard_path, learner_cohort_path(cohort) ].each do |path|
        get path
        expect(response).to redirect_to(new_learner_session_path)
        expect(response.headers["Cache-Control"].to_s).not_to include("public")
      end
    end
  end

  context "when signed in" do
    before { sign_in learner }

    it "sends Cache-Control no-store on /my and the cohort page" do
      get learner_dashboard_path
      expect(response.headers["Cache-Control"]).to include("no-store")

      get learner_cohort_path(cohort)
      expect(response).to have_http_status(:ok)
      expect(response.headers["Cache-Control"]).to include("no-store")
    end

    it "keeps the learner's links out of the session breadcrumbs" do
      get learner_cohort_path(cohort)
      expect(Nokogiri::HTML(response.body).css(".breadcrumbs a").map { |a| a["href"] }).to include(learner_dashboard_path)

      paths = Array(session[:breadcrumbs]).map { |crumb| crumb["path"] || crumb[:path] }
      expect(paths).not_to include(learner_dashboard_path, learner_cohort_path(cohort))
    end

    describe "dashboard" do
      it "shows only enrollments whose program is on this domain, with today's items and progress" do
        foreign_program = create(:program, title: "برنامج موقع آخر", published: true).tap { |p| p.update!(domains: [ other_domain ]) }
        create(:enrollment, learner: learner, cohort: create(:cohort, program: foreign_program), domain: other_domain)

        get learner_dashboard_path

        expect(response.body).to include(program.title, cohort.name, learner_cohort_path(cohort))
        expect(response.body).not_to include("برنامج موقع آخر")
        expect(response.body).to include("الدروس المسموعة: 0 من 3", "عليك درس متأخر — الدرس 1: شرح القواعد الأربع ١",
                                         learner_cohort_path(cohort, anchor: ActionView::RecordIdentifier.dom_id(first_lesson)))
      end
    end

    describe "cohort timeline" do
      it "returns not found for another learner's cohort" do
        other_cohort = create(:cohort, program: program)
        create(:enrollment, cohort: other_cohort, domain: domain)

        get learner_cohort_path(other_cohort)

        expect(response).to have_http_status(:not_found)
        expect(response.headers["Cache-Control"]).to include("no-store")
      end

      it "returns not found for an enrollment whose program is not on this domain" do
        program.update!(domains: [ other_domain ])
        get learner_cohort_path(cohort)
        expect(response).to have_http_status(:not_found)
      end

      it "shows released items, the matn and the future lesson's date, in order" do
        get learner_cohort_path(cohort)

        body = response.body
        expect(body).to include("شرح القواعد الأربع ١", "متن القواعد الأربع", "يُتاح الثلاثاء 25 نوفمبر")
        expect(body.index("شرح القواعد الأربع ١")).to be < body.index("متن القواعد الأربع")
        expect(Nokogiri::HTML(body).css("form[action^='#{learner_cohort_completions_path(cohort)}?']").size).to eq(2)
      end

      it "shows the exam window in the cohort time zone" do
        get learner_cohort_path(cohort)
        expect(response.body).to include("من الأربعاء 19 نوفمبر إلى الجمعة 21 نوفمبر، الساعة 10:00 م", "يُفتح الأربعاء 19 نوفمبر",
                                         "المواعيد بتوقيت مكة المكرمة")
      end

      it "says an exam without questions is not available yet, even inside its window" do
        placeholder = scheduled_exam(position: 6, exam: create(:exam, program: program, title: "اختبار لم يكتب"))
        travel_to riyadh.local(2025, 11, 20, 12)

        get learner_cohort_path(cohort)

        row = Nokogiri::HTML(response.body).at_css("##{ActionView::RecordIdentifier.dom_id(placeholder)}")
        expect(row.text).to include("غير متاح بعد")
        expect(row.text).not_to include("يُفتح في")
      end

      it "shows the score of a submitted exam" do
        create(:exam_attempt, enrollment: enrollment, exam: exam.exam, score_percent: 67)
        get learner_cohort_path(cohort)
        expect(response.body).to include("نتيجتك 67٪")
      end

      it "issues a certificate that became due when the page loads" do
        exam.cohort_slots.destroy_all
        future_lesson.cohort_slots.destroy_all
        [ first_lesson, second_lesson ].each { |item| create(:lesson_completion, enrollment: enrollment, program_item: item) }

        get learner_cohort_path(cohort)

        expect(enrollment.reload.certificate).to be_present
        expect(response.body).to include(enrollment.certificate.number)
      end

      it "runs the same number of queries for 3 lessons as for 10" do
        count_queries = lambda do
          queries = 0
          counter = ->(*, payload) { queries += 1 unless payload[:name] == "SCHEMA" || payload[:cached] }
          ActiveSupport::Notifications.subscribed(counter, "sql.active_record") { get learner_cohort_path(cohort) }
          queries
        end

        count_queries.call # warms up the session
        few = count_queries.call
        7.times { |n| scheduled(:lesson, position: 10 + n, on: Date.new(2025, 11, 8)) }
        2.times { |n| scheduled_exam(position: 20 + n) }
        expect(count_queries.call).to eq(few)
      end
    end

    describe "ticking" do
      it "ticks an available lesson via Turbo Stream" do
        tick(second_lesson)

        expect(response).to have_http_status(:ok)
        expect(response.media_type).to eq("text/vnd.turbo-stream.html")
        expect(response.headers["Cache-Control"]).to include("no-store")
        expect(LessonCompletion.where(enrollment: enrollment, program_item: second_lesson)).to exist
        expect(response.body).to include(%(target="#{ActionView::RecordIdentifier.dom_id(second_lesson)}"), "الدروس المسموعة: 1 من 3")
      end

      it "opens the exam row when the last earlier lesson is ticked" do
        travel_to riyadh.local(2025, 11, 20, 12)
        tick(first_lesson)

        tick(second_lesson)

        expect(response.body).to include(%(target="#{ActionView::RecordIdentifier.dom_id(exam)}"), "الاختبار متاح الآن")
      end

      it "rejects ticking a future lesson, telling the learner why" do
        tick(future_lesson)

        expect(response).to have_http_status(:unprocessable_content)
        expect(response.body).to include('target="program_flash"', "لا يمكن تعليم هذا الدرس الآن")
        expect(response.headers["Cache-Control"]).to include("no-store")
        expect(LessonCompletion.count).to eq(0)
      end

      it "rejects a crafted HTML tick of a future lesson with a message" do
        tick(future_lesson, headers: {})

        expect(response).to redirect_to(learner_cohort_path(cohort))
        expect(flash[:alert]).to be_present
        expect(LessonCompletion.count).to eq(0)
      end

      it "rejects an item of another program" do
        tick(create(:program_item, :lesson))
        expect(response).to have_http_status(:unprocessable_content)
      end

      it "sends no-store on a successful tick" do
        tick(first_lesson)
        expect(response.headers["Cache-Control"]).to include("no-store")
      end

      it "falls back to a redirect without Turbo" do
        tick(first_lesson, headers: {})
        expect(response).to redirect_to(learner_cohort_path(cohort))
        expect(LessonCompletion.count).to eq(1)
      end
    end

    describe "next steps" do
      def row(item)
        Nokogiri::HTML(response.body).at_css("##{ActionView::RecordIdentifier.dom_id(item)}")
      end

      it "numbers lessons, marks today's lesson, dates the overdue one and points to it" do
        get learner_cohort_path(cohort)

        expect(row(first_lesson).text.squish).to include("1", "موعده أمس · متأخر")
        expect(row(second_lesson).text.squish).to include("2", "درس اليوم")
        expect(row(future_lesson).text.squish).to include("3", "يُتاح الثلاثاء 25 نوفمبر")
        header = Nokogiri::HTML(response.body).at_css("#cohort_header")
        expect(header.text.squish).to include("عليك درس متأخر — الدرس 1: شرح القواعد الأربع ١")
        expect(header.at_css("a[href='##{ActionView::RecordIdentifier.dom_id(first_lesson)}']")).to be_present
      end

      it "names each tick button after its lesson" do
        get learner_cohort_path(cohort)
        expect(row(first_lesson).at_css("button[aria-label='سمعت: شرح القواعد الأربع ١']")).to be_present
      end

      it "after the day's last tick, confirms and says when the next lesson comes, with an undo" do
        tick(first_lesson)
        tick(second_lesson)

        expect(response.body).to include("أحسن الله إليك.", "أتممت دروس اليوم ✓ — الدرس التالي الثلاثاء 25 نوفمبر",
                                         learner_cohort_completion_path(cohort, second_lesson.id))
      end

      it "undoes a tick" do
        tick(first_lesson)

        delete learner_cohort_completion_path(cohort, first_lesson.id), headers: turbo_stream

        expect(response).to have_http_status(:ok)
        expect(response.body).to include("تم التراجع عن تعليم الدرس.")
        expect(LessonCompletion.count).to eq(0)
      end

      it "refuses an undo once a later exam has an attempt" do
        tick(first_lesson)
        create(:exam_attempt, enrollment: enrollment, exam: exam.exam, score_percent: 80)

        delete learner_cohort_completion_path(cohort, first_lesson.id), headers: turbo_stream

        expect(response).to have_http_status(:unprocessable_content)
        expect(response.body).to include("لا يمكن التراجع عن تعليم هذا الدرس الآن.")
        expect(LessonCompletion.count).to eq(1)
      end

      it "puts an open exam ahead of lessons that are still due after it" do
        travel_to riyadh.local(2025, 11, 20, 12)
        tick(first_lesson)
        tick(second_lesson)
        scheduled(:lesson, position: 6, on: Date.new(2025, 11, 20))

        get learner_cohort_path(cohort)

        header = Nokogiri::HTML(response.body).at_css("#cohort_header").text.squish
        expect(header).to include("متاح الآن، ويُغلق الجمعة 21 نوفمبر، الساعة 10:00 م")
      end

      it "doesn't call a learner who missed an exam finished" do
        future_lesson.cohort_slots.destroy_all
        tick(first_lesson)
        tick(second_lesson)
        travel_to riyadh.local(2025, 11, 22, 12)

        get learner_cohort_path(cohort)

        header = Nokogiri::HTML(response.body).at_css("#cohort_header").text.squish
        expect(header).to include("دون استيفاء شرط الشهادة")
        expect(header).not_to include("أتممت دروس البرنامج واختباراته")
      end

      it "shows a midnight close as the end of the previous day, with no time left out" do
        exam.cohort_slots.sole.update!(closes_at: riyadh.local(2025, 11, 22))

        get learner_cohort_path(cohort)

        expect(row(exam).text.squish).to include("إلى الجمعة 21 نوفمبر، آخر اليوم")
      end

      it "says an exam without questions is not available yet, never that it opened yesterday" do
        future_lesson.cohort_slots.destroy_all
        exam.exam.questions.destroy_all
        tick(first_lesson)
        tick(second_lesson)
        travel_to riyadh.local(2025, 11, 20, 12)

        get learner_cohort_path(cohort)

        header = Nokogiri::HTML(response.body).at_css("#cohort_header").text.squish
        expect(header).to include("غير متاح بعد")
        expect(header).not_to include("أمس")
      end

      it "never calls a learner finished when an exam without questions has closed" do
        future_lesson.cohort_slots.destroy_all
        exam.exam.questions.destroy_all
        tick(first_lesson)
        tick(second_lesson)
        travel_to riyadh.local(2025, 11, 22, 12)

        get learner_cohort_path(cohort)

        header = Nokogiri::HTML(response.body).at_css("#cohort_header").text.squish
        expect(header).to include("دون استيفاء شرط الشهادة")
        expect(header).not_to include("أتممت دروس البرنامج واختباراته")
      end

      describe "undo refusals" do
        it "refuses once a certificate exists" do
          tick(first_lesson)
          Certificate.create!(enrollment: enrollment, domain: domain, issued_at: Time.current, number: "X-1",
                              full_name_snapshot: learner.full_name, gender_snapshot: learner.gender)

          delete learner_cohort_completion_path(cohort, first_lesson.id), headers: turbo_stream

          expect(response).to have_http_status(:unprocessable_content)
          expect(LessonCompletion.count).to eq(1)
        end

        it "refuses a lesson that was never ticked" do
          delete learner_cohort_completion_path(cohort, first_lesson.id), headers: turbo_stream
          expect(response).to have_http_status(:unprocessable_content)
        end

        it "allows it when only an earlier exam has an attempt" do
          earlier = scheduled_exam(position: 0)
          create(:exam_attempt, enrollment: enrollment, exam: earlier.exam, score_percent: 80)
          tick(first_lesson)

          delete learner_cohort_completion_path(cohort, first_lesson.id), headers: turbo_stream

          expect(response).to have_http_status(:ok)
          expect(LessonCompletion.count).to eq(0)
        end

        it "returns not found for another learner's cohort" do
          other_cohort = create(:cohort, program: program)
          other = create(:enrollment, cohort: other_cohort, domain: domain)
          item = create(:program_item, :lesson, program: program, position: 40)
          create(:lesson_completion, enrollment: other, program_item: item)

          delete learner_cohort_completion_path(other_cohort, item.id), headers: turbo_stream

          expect(response).to have_http_status(:not_found)
          expect(LessonCompletion.count).to eq(1)
        end

        it "refuses an item of another program" do
          delete learner_cohort_completion_path(cohort, create(:program_item, :lesson).id), headers: turbo_stream
          expect(response).to have_http_status(:unprocessable_content)
        end

        it "redirects back to the timeline with a message without Turbo" do
          delete learner_cohort_completion_path(cohort, first_lesson.id)

          expect(response).to redirect_to(learner_cohort_path(cohort))
          expect(flash[:alert]).to eq(I18n.t("programs.cohort.untick_refused"))
        end
      end

      it "speaks to a female learner in the feminine" do
        learner.update!(gender: :female)
        travel_to riyadh.local(2025, 11, 20, 12)

        get learner_cohort_path(cohort)

        expect(row(exam).text).to include("أكملي سماع الدروس السابقة أولًا")
      end

      it "lists followed cohorts before one that hasn't started, which says when it starts" do
        later = create(:cohort, program: program, name: "دفعة قادمة", starts_on: Date.new(2025, 11, 19))
        create(:enrollment, learner: learner, cohort: later, domain: domain, enrolled_at: 1.minute.from_now)

        get learner_dashboard_path

        body = response.body
        expect(body.index(cohort.name)).to be < body.index("دفعة قادمة")
        expect(body).to include("تبدأ الدفعة يوم الأربعاء 19 نوفمبر (بعد 10 أيام)")
      end
    end

    describe "playing" do
      let(:lesson) { first_lesson.lesson }

      before do
        lesson.audio.attach(io: StringIO.new("audio"), filename: "lesson.mp3", content_type: "audio/mpeg")
        lesson.update!(published: false)
      end

      it "plays an available lesson in the site player, even when unpublished in the library" do
        get learner_cohort_play_path(cohort, first_lesson), headers: turbo_stream

        expect(response).to have_http_status(:ok)
        expect(response.body).to include('target="audio-player"', ERB::Util.h(lesson.title))
        expect(response.body).to include(ERB::Util.h("هل أتممت سماع الدرس 1: #{first_lesson.display_title}؟"),
                                         learner_cohort_completions_path(cohort, program_item_id: first_lesson.id))
      end

      it "sends no-store" do
        get learner_cohort_play_path(cohort, first_lesson), headers: turbo_stream
        expect(response.headers["Cache-Control"]).to include("no-store")
      end

      it "refuses a lesson that is not released yet" do
        future_lesson.lesson.audio.attach(io: StringIO.new("audio"), filename: "lesson.mp3", content_type: "audio/mpeg")
        get learner_cohort_play_path(cohort, future_lesson), headers: turbo_stream
        expect(response).to have_http_status(:not_found)
        expect(response.headers["Cache-Control"]).to include("no-store")
      end

      it "refuses a hidden item, another program's item and an item with no slot" do
        hidden = scheduled(:lesson, position: 30, on: Date.new(2025, 11, 8), hidden: true, lesson: lesson)
        unscheduled = create(:program_item, :lesson, program: program, position: 31, lesson: lesson)
        foreign = create(:program_item, :lesson, lesson: lesson)
        create(:cohort_slot, program_item: foreign, cohort: create(:cohort, program: foreign.program), available_on: Date.new(2025, 11, 8))

        [ hidden, unscheduled, foreign ].each do |item|
          get learner_cohort_play_path(cohort, item), headers: turbo_stream
          expect(response).to have_http_status(:not_found)
        end
      end
    end
  end
end
