require_relative './base'

module Seeds
  class FatwasSeeder < Base
    HAJRI_FATWAS = [
      {
        title: "فتوى حول الصلاة في الأوقات المكروهة",
        category: "الصلاة",
        question: "هل يجوز الصلاة في الأوقات المكروهة؟",
        answer: "الصلاة في الأوقات المكروهة جائزة إلا إذا كانت سنة مؤكدة.",
        source_url: "https://example.com/fatwa1",
        has_audio: true
      },
      {
        title: "فتوى حول الصيام في شهر رمضان",
        category: "الصيام",
        question: "ما حكم الصيام في شهر رمضان؟",
        answer: "الصيام في شهر رمضان فرض على كل مسلم بالغ عاقل.",
        source_url: "https://example.com/fatwa2",
        has_audio: true
      },
      {
        title: "فتوى حول الزكاة والصدقات",
        category: "الزكاة",
        question: "ما هي الزكاة وكيف تُحسب؟",
        answer: "الزكاة فريضة مالية تُخرج على المال الزائد عن الحاجة.",
        source_url: "https://example.com/fatwa3",
        has_audio: false
      }
    ].freeze

    ALFAWZAN_FATWAS = [
      {
        title: "حكم الصلاة على الميت الغائب",
        category: "الصلاة",
        question: "ما حكم الصلاة على الميت الغائب؟",
        answer: "الصلاة على الغائب مشروعة إذا كان له شأن في الإسلام ولم يُصلَّ عليه في بلده.",
        source_url: "https://example.com/alfawzan/fatwa1",
        has_audio: true
      },
      {
        title: "حكم صيام يوم الشك",
        category: "الصيام",
        question: "ما حكم صيام يوم الشك؟",
        answer: "يوم الشك هو يوم الثلاثين من شعبان إذا حال دون رؤية الهلال غيم أو نحوه، والصحيح أنه لا يجوز صومه.",
        source_url: "https://example.com/alfawzan/fatwa2",
        has_audio: true
      },
      {
        title: "الفرق بين الرياء والسمعة",
        category: "العقيدة",
        question: "ما الفرق بين الرياء والسمعة؟",
        answer: "الرياء: أن يعمل العمل ليراه الناس. والسمعة: أن يعمل ليسمع الناس به. وكلاهما شرك أصغر.",
        source_url: "https://example.com/alfawzan/fatwa3",
        has_audio: false
      }
    ].freeze

    def self.seed(from: nil, domain_ids: nil, scholar: nil)
      scholar ||= default_scholar
      fatwas_data = scholar.full_name&.include?("الفوزان") ? ALFAWZAN_FATWAS : HAJRI_FATWAS

      puts "Seeding fatwas for #{scholar.full_name}..."
      processed = 0

      fatwas_data.each do |data|
        fatwa = Fatwa.find_or_initialize_by(title: data[:title]) do |f|
          f.category = data[:category]
          f.scholar = scholar
          f.question = data[:question]
          f.answer = data[:answer]
          f.source_url = data[:source_url]
          f.published = true
          f.published_at = Date.today
        end

        if fatwa.save
          processed += 1
          assign_to_domains(fatwa, domain_ids)
          attach_fixture(fatwa, :audio, :audio) if data[:has_audio] && !fatwa.audio.attached?
        end
        print "." if processed % 5 == 0
      end

      puts "\nSeeded #{processed} fatwas"
    end
  end
end
