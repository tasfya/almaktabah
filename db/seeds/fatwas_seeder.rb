require_relative './base'

module Seeds
  class FatwasSeeder < Base
    def self.seed(from: nil, domain_ids: nil)
      puts "Seeding fatwas..."
      scholar = default_scholar
      processed = 0

      fatwas_data = [
        {
          title: "فتوى حول الصلاة في الأوقات المكروهة",
          category: "الصلاة",
          question: "هل يجوز الصلاة في الأوقات المكروهة؟",
          answer: "الصلاة في الأوقات المكروهة جائزة إلا إذا كانت سنة مؤكدة.",
          source_url: "https://example.com/fatwa1"
        },
        {
          title: "فتوى حول الصيام في شهر رمضان",
          category: "الصيام",
          question: "ما حكم الصيام في شهر رمضان؟",
          answer: "الصيام في شهر رمضان فرض على كل مسلم بالغ عاقل.",
          source_url: "https://example.com/fatwa2"
        },
        {
          title: "فتوى حول الزكاة والصدقات",
          category: "الزكاة",
          question: "ما هي الزكاة وكيف تُحسب؟",
          answer: "الزكاة فريضة مالية تُخرج على المال الزائد عن الحاجة.",
          source_url: "https://example.com/fatwa3"
        }
      ]

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
          assign_to_domain(fatwa, domain_ids)
        end
        print "." if processed % 5 == 0
      end

      puts "\nSeeded #{processed} fatwas"
    end
  end
end
