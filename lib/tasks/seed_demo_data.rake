# Populate content to existing domains
# bundle exec rake db:populate_content

# Clear existing content and populate fresh
# CLEAR=true bundle exec rake db:populate_content

# Only clear existing content
# bundle exec rake db:clear_seed_content

namespace :db do
  desc "Clear all seeded content from the database"
  task clear_seed_content: :environment do
    if Rails.env.production?
      puts "❌ This task is not allowed in production environment!"
      exit 1
    end

    puts "🧹 Clearing seeded content..."

    DomainAssignment.delete_all
    Lesson.delete_all
    News.delete_all
    Fatwa.delete_all
    Benefit.delete_all
    Lecture.delete_all
    Series.delete_all
    Book.delete_all
    Scholar.delete_all
    FriendlyId::Slug.delete_all

    puts "✅ Seeded content cleared successfully!"
  end

  desc "Populate database with Islamic content (Arabic and English)"
  task populate_content: :environment do
    if Rails.env.production?
      puts "❌ This task is not allowed in production environment!"
      exit 1
    end

    require "faker"
    require "factory_bot_rails"
    require_relative "../../db/seeds/base"

    puts "🌱 Starting content population..."

    if ENV["CLEAR"] == "true"
      puts "🧹 Clearing existing content..."

      DomainAssignment.delete_all
      Lesson.delete_all
      News.delete_all
      Fatwa.delete_all
      Benefit.delete_all
      Lecture.delete_all
      Series.delete_all
      Book.delete_all
      Scholar.delete_all
      FriendlyId::Slug.delete_all

      puts "✅ Existing content cleared"
    end

    existing_domains = Domain.all
    if existing_domains.empty?
      puts "❌ No domains found! Please create at least one domain first."
      puts "   You can create a domain through the admin interface or run:"
      puts "   Domain.create!(name: 'localhost', host: 'localhost')"
      exit 1
    end

    puts "📍 Found #{existing_domains.count} domain(s): #{existing_domains.pluck(:name).join(', ')}"

    def assign_to_all_domains(record, domains)
      return unless record.persisted?
      domains.each do |domain|
        record.domain_assignments.find_or_create_by!(domain_id: domain.id)
      end
    end

    # Arabic content arrays
    arabic_scholar_names = [
      [ "محمد", "الغزالي" ], [ "أحمد", "الشافعي" ], [ "عبد الله", "القرطبي" ],
      [ "يوسف", "القرضاوي" ], [ "محمد", "العثيمين" ], [ "عبد العزيز", "بن باز" ],
      [ "صالح", "الفوزان" ], [ "ناصر", "الدين الألباني" ], [ "أبو بكر", "الجزائري" ],
      [ "عبد الرحمن", "السعدي" ], [ "محمد", "الطبري" ], [ "ابن", "تيمية" ],
      [ "ابن", "القيم" ], [ "ابن", "كثير" ], [ "النووي", "" ],
      [ "البخاري", "" ], [ "مسلم", "" ], [ "أبو داود", "" ], [ "الترمذي", "" ],
      [ "John", "Smith" ], [ "Michael", "Johnson" ], [ "David", "Williams" ]
    ]

    arabic_book_titles = [
      "تفسير القرآن الكريم", "صحيح البخاري", "صحيح مسلم", "سنن أبي داود",
      "جامع الترمذي", "سنن النسائي", "سنن ابن ماجه", "موطأ مالك",
      "الأربعين النووية", "رياض الصالحين", "بلوغ المرام", "عمدة الأحكام",
      "زاد المعاد", "مدارج السالكين", "إعلام الموقعين", "الطب النبوي",
      "فقه السنة", "فقه الزكاة", "فقه الصيام", "فقه الحج",
      "Introduction to Islamic Studies", "The Quran: A New Translation",
      "Understanding Islam", "Islamic History"
    ]

    arabic_categories = [
      "التفسير", "الحديث", "الفقه", "العقيدة", "السيرة النبوية",
      "التاريخ الإسلامي", "الأخلاق والآداب", "الدعوة", "التربية الإسلامية",
      "Religious Studies", "Islamic Philosophy"
    ]

    arabic_lecture_titles = [
      "دروس في التفسير", "شرح الأربعين النووية", "دروس في الفقه",
      "محاضرات في العقيدة", "قصص الأنبياء", "السيرة النبوية",
      "أحكام الصلاة", "أحكام الزكاة", "أحكام الصيام", "أحكام الحج",
      "الأخلاق في الإسلام", "آداب الطعام والشراب", "برّ الوالدين",
      "حقوق الجار", "الدعوة إلى الله", "طلب العلم", "الصبر والشكر",
      "Islamic Ethics", "Understanding the Quran", "Prayer in Islam", "Patience in Islam"
    ]

    arabic_news_titles = [
      "انطلاق مؤتمر العلماء السنوي", "افتتاح مكتبة إسلامية جديدة",
      "ندوة حول التربية الإسلامية", "مؤتمر الشباب المسلم",
      "ورشة عمل في تحفيظ القرآن", "محاضرة حول الأخلاق الإسلامية",
      "إطلاق برنامج تعليمي جديد", "مسابقة في الثقافة الإسلامية",
      "New Islamic Center Opens", "Youth Conference on Islamic Values"
    ]

    arabic_series_titles = [
      "سلسلة دروس التفسير", "سلسلة الأحاديث النبوية", "سلسلة الفقه الميسر",
      "سلسلة العقيدة الصحيحة", "سلسلة السيرة النبوية", "سلسلة الأخلاق الإسلامية",
      "سلسلة أحكام العبادات", "سلسلة قصص القرآن", "سلسلة التربية الإسلامية",
      "Basic Islamic Studies Series", "Understanding Islam Series"
    ]

    arabic_fatwa_questions = [
      "ما حكم صلاة الجماعة؟", "ما حكم الزكاة على الذهب؟", "ما حكم صيام المريض؟",
      "ما حكم الحج عن الغير؟", "ما حكم قراءة القرآن للحائض؟", "ما حكم التيمم عند فقدان الماء؟",
      "ما حكم الوضوء من أكل لحم الإبل؟", "ما حكم الجمع بين الصلاتين؟", "ما حكم قصر الصلاة في السفر؟",
      "What is the ruling on congregational prayer?", "Can women attend mosque prayers?"
    ]

    arabic_benefit_titles = [
      "فائدة في الوضوء", "فائدة في الصلاة", "فائدة في الزكاة", "فائدة في الصيام",
      "فائدة في الحج", "فائدة في التلاوة", "فائدة في الذكر", "فائدة في الدعاء",
      "فائدة في الأخلاق", "فائدة في السلوك", "Daily Islamic Reminder", "Islamic Etiquette Tip"
    ]

    # Create scholars
    puts "Creating scholars..."
    scholars = []
    20.times do |i|
      first_name, last_name = arabic_scholar_names[i % arabic_scholar_names.length]

      bio = if i < 17
        "عالم متخصص في العلوم الشرعية، له مؤلفات عديدة ومشاركات علمية متنوعة في مجال الدراسات الإسلامية والفقه."
      else
        "Islamic scholar specializing in Islamic studies with numerous publications and contributions to the field of Islamic jurisprudence and theology."
      end

      scholar = FactoryBot.create(:scholar,
        first_name: first_name,
        last_name: last_name,
        bio: bio
      )
      scholars << scholar
      print "."
    end
    puts "\n✅ Created #{scholars.count} scholars"

    # Create books
    puts "Creating books..."
    books_created = 0
    20.times do |i|
      title = arabic_book_titles[i % arabic_book_titles.length]
      title = "#{title} - الجزء #{i + 1}" if Book.exists?(title: title)

      description = if i < 17
        "#{title} كتاب مفيد في #{arabic_categories.sample}، يحتوي على معلومات قيمة ومفيدة للقارئ المسلم. يتناول الكتاب موضوعات مهمة بأسلوب واضح ومبسط."
      else
        "#{title} is a comprehensive guide covering important topics in Islamic studies. This book provides valuable insights and practical guidance for Muslims seeking to deepen their understanding of their faith."
      end

      book = FactoryBot.create(:book, :without_domain,
        title: title,
        author: scholars.sample,
        category: arabic_categories.sample,
        description: description,
        published_at: Faker::Date.between(from: 2.years.ago, to: Date.today),
        pages: rand(50..800),
        downloads: rand(0..1000),
        published: true
      )

      assign_to_all_domains(book, existing_domains)
      books_created += 1
      print "."
    end
    puts "\n✅ Created #{books_created} books"

    # Create series
    puts "Creating series..."
    series_created = 0
    20.times do |i|
      title = arabic_series_titles[i % arabic_series_titles.length]
      title = "#{title} - الموسم #{i + 1}" if Series.exists?(title: title)

      description = if i < 17
        "#{title} سلسلة تعليمية مفيدة تتناول موضوعات مهمة في #{arabic_categories.sample}. تهدف هذه السلسلة إلى تقديم المعرفة الشرعية بطريقة منهجية ومبسطة."
      else
        "#{title} is an educational series covering important topics in Islamic studies, designed to provide systematic and accessible religious knowledge."
      end

      series = FactoryBot.create(:series, :without_domain,
        title: title,
        scholar: scholars.sample,
        category: arabic_categories.sample,
        description: description,
        published_at: Faker::Date.between(from: 1.year.ago, to: Date.today),
        published: true
      )

      assign_to_all_domains(series, existing_domains)
      series_created += 1
      print "."
    end
    puts "\n✅ Created #{series_created} series"

    # Create lessons for series
    puts "Creating lessons..."
    lessons_created = 0
    Series.includes(:scholar).limit(10).each do |series|
      rand(2..5).times do |lesson_num|
        title = "الدرس #{lesson_num + 1}: #{arabic_lecture_titles.sample}"

        lesson = FactoryBot.create(:lesson,
          title: title,
          series: series,
          published_at: Faker::Date.between(from: series.published_at, to: Date.today),
          published: true,
          duration: rand(15..90),
          description: "درس مفيد ضمن #{series.title}، يتناول موضوعات مهمة بأسلوب واضح ومفهوم.",
          content: "محتوى الدرس يشمل شرحاً وافياً للموضوع مع الأدلة من القرآن والسنة. يهدف هذا الدرس إلى تقديم المعلومات بطريقة سهلة الفهم والتطبيق.\n\nالنقاط الرئيسية:\n- النقطة الأولى\n- النقطة الثانية\n- النقطة الثالثة\n\nخلاصة الدرس تؤكد على أهمية التطبيق العملي للمعرفة المكتسبة."
        )

        assign_to_all_domains(lesson, existing_domains)
        lessons_created += 1
        print "."
      end
    end
    puts "\n✅ Created #{lessons_created} lessons"

    # Create lectures
    puts "Creating lectures..."
    lectures_created = 0
    20.times do |i|
      title = arabic_lecture_titles[i % arabic_lecture_titles.length]
      title = "#{title} - المحاضرة #{i + 1}" if Lecture.exists?(title: title)

      description = if i < 17
        "محاضرة قيمة في #{arabic_categories.sample} تتناول موضوعات مهمة بأسلوب علمي مبسط."
      else
        "Valuable lecture on #{arabic_categories.sample} covering important topics with a scholarly yet accessible approach."
      end

      content = if i < 17
        "محتوى المحاضرة يشمل مقدمة شاملة عن الموضوع، مع التطرق إلى النقاط الرئيسية والفرعية. تتضمن المحاضرة أدلة من القرآن الكريم والسنة النبوية المطهرة.\n\nمحاور المحاضرة:\n- المحور الأول: التعريف والأهمية\n- المحور الثاني: الأحكام والضوابط\n- المحور الثالث: التطبيق العملي\n\nختام المحاضرة يؤكد على الاستفادة العملية من المحتوى المقدم."
      else
        "This lecture provides a comprehensive introduction to the topic, covering main and subsidiary points. The content includes evidence from the Quran and authentic Prophetic traditions.\n\nLecture outline:\n- Section 1: Definition and Importance\n- Section 2: Rules and Guidelines\n- Section 3: Practical Application\n\nThe conclusion emphasizes practical benefits from the presented content."
      end

      lecture = FactoryBot.create(:lecture, :with_domain,
        title: title,
        scholar: scholars.sample,
        category: arabic_categories.sample,
        description: description,
        content: content,
        duration: rand(30..120),
        kind: [ :sermon, :conference, :benefit ].sample,
        published: true,
        published_at: Faker::Date.between(from: 1.year.ago, to: Date.today)
      )

      assign_to_all_domains(lecture, existing_domains)
      lectures_created += 1
      print "."
    end
    puts "\n✅ Created #{lectures_created} lectures"

    # Create benefits
    puts "Creating benefits..."
    benefits_created = 0
    20.times do |i|
      title = arabic_benefit_titles[i % arabic_benefit_titles.length]
      title = "#{title} #{i + 1}" if Benefit.exists?(title: title)

      description = if i < 17
        "فائدة مختصرة ومفيدة تتناول موضوعاً مهماً في #{arabic_categories.sample}."
      else
        "A brief and beneficial reminder covering an important topic in #{arabic_categories.sample}."
      end

      content = if i < 17
        "هذه فائدة قصيرة ومركزة تهدف إلى تقديم معلومة مفيدة أو تذكير مهم للمسلم في حياته اليومية. الفائدة مستقاة من القرآن الكريم والسنة النبوية الشريفة.\n\nالنقاط المهمة:\n- نقطة مهمة للتذكر\n- تطبيق عملي\n- فائدة للحياة اليومية"
      else
        "This is a short, focused benefit aimed at providing useful information or an important reminder for Muslims in their daily lives. The content is derived from the Quran and authentic Prophetic traditions.\n\nKey points:\n- Important point to remember\n- Practical application\n- Daily life benefit"
      end

      benefit = FactoryBot.create(:benefit,
        title: title,
        scholar: scholars.sample,
        category: arabic_categories.sample,
        description: description,
        content: content,
        duration: rand(2..15),
        published_at: Faker::Date.between(from: 3.months.ago, to: Date.today),
        published: true
      )

      assign_to_all_domains(benefit, existing_domains)
      benefits_created += 1
      print "."
    end
    puts "\n✅ Created #{benefits_created} benefits"

    # Create fatwas
    puts "Creating fatwas..."
    fatwas_created = 0
    20.times do |i|
      question = arabic_fatwa_questions[i % arabic_fatwa_questions.length]
      title = question.length > 50 ? "#{question[0..47]}..." : question
      title = "#{title} (#{i + 1})" if Fatwa.exists?(title: title)

      answer = if i < 17
        "الحمد لله والصلاة والسلام على رسول الله، وبعد:\n\nبالنسبة لسؤالكم، فإن الجواب كما يلي:\n\nأولاً: التعريف والتوضيح\nالموضوع المسؤول عنه له أحكام شرعية واضحة في القرآن والسنة.\n\nثانياً: الأدلة الشرعية\nمن القرآن الكريم: الآيات التي تتناول هذا الموضوع تبين الحكم بوضوح.\nمن السنة النبوية: الأحاديث الصحيحة تؤكد هذا الحكم.\n\nثالثاً: الخلاصة\nالحكم في هذه المسألة واضح، ويجب على المسلم اتباع ما جاء في الشرع الحنيف.\n\nوالله تعالى أعلم."
      else
        "Praise be to Allah, and peace and blessings upon the Messenger of Allah. Regarding your question:\n\nFirst: Definition and Clarification\nThe matter you asked about has clear Islamic rulings in the Quran and Sunnah.\n\nSecond: Islamic Evidence\nFrom the Quran: Verses addressing this topic clearly show the ruling.\nFrom the Prophetic Sunnah: Authentic narrations confirm this ruling.\n\nThird: Conclusion\nThe ruling on this matter is clear, and Muslims should follow what has been established in Islamic law.\n\nAllah knows best."
      end

      fatwa = FactoryBot.create(:fatwa, :without_domain,
        title: title,
        category: arabic_categories.sample,
        question: question,
        answer: answer,
        published_at: Faker::Date.between(from: 6.months.ago, to: Date.today),
        published: true
      )

      assign_to_all_domains(fatwa, existing_domains)
      fatwas_created += 1
      print "."
    end
    puts "\n✅ Created #{fatwas_created} fatwas"

    # Create news
    puts "Creating news..."
    news_created = 0
    20.times do |i|
      title = arabic_news_titles[i % arabic_news_titles.length]
      title = "#{title} - #{Date.today.year}" if News.exists?(title: title)

      description = if i < 17
        "خبر مهم يتعلق بالأنشطة الإسلامية والتعليمية في المجتمع."
      else
        "Important news related to Islamic and educational activities in the community."
      end

      content = if i < 17
        "تفاصيل الخبر تشمل معلومات مهمة حول الحدث أو النشاط المذكور. هذا الحدث يأتي ضمن الجهود المستمرة لخدمة المجتمع المسلم وتقديم الأنشطة التعليمية والثقافية المفيدة.\n\nالتفاصيل:\n- التاريخ والمكان\n- المشاركون والحضور\n- الأهداف والنتائج المتوقعة\n\nهذا النشاط يهدف إلى تعزيز المعرفة الإسلامية وخدمة المجتمع بشكل عام."
      else
        "News details include important information about the mentioned event or activity. This event is part of ongoing efforts to serve the Muslim community and provide beneficial educational and cultural activities.\n\nDetails:\n- Date and venue\n- Participants and attendees\n- Objectives and expected outcomes\n\nThis activity aims to enhance Islamic knowledge and serve the community in general."
      end

      news = FactoryBot.create(:news, :without_domain,
        title: title,
        description: description,
        content: content,
        published_at: Faker::Date.between(from: 1.month.ago, to: Date.today),
        published: true
      )

      assign_to_all_domains(news, existing_domains)
      news_created += 1
      print "."
    end
    puts "\n✅ Created #{news_created} news articles"

    puts "\n🎉 Content population completed successfully!"
    puts "📊 Summary:"
    puts "   👨‍🏫 Scholars: #{Scholar.count}"
    puts "   📚 Books: #{Book.count}"
    puts "   📺 Series: #{Series.count}"
    puts "   🎓 Lessons: #{Lesson.count}"
    puts "   🎤 Lectures: #{Lecture.count}"
    puts "   💡 Benefits: #{Benefit.count}"
    puts "   ❓ Fatwas: #{Fatwa.count}"
    puts "   📰 News: #{News.count}"
    puts "   🔗 Domain Assignments: #{DomainAssignment.count}"
    puts "   🌐 Domains: #{existing_domains.map { |d| "#{d.name} (#{d.host})" }.join(', ')}"

    puts "\n✨ Your database is now populated with diverse Islamic content!"
    puts "🔤 Content mix: ~85% Arabic, ~15% English"
    puts "📋 Usage: All content is properly assigned to all existing domains"
    puts "🚀 You can now test the application with realistic data!"
  end
end
