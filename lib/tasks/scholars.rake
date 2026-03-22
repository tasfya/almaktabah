namespace :scholars do
  desc "Assign scholars' content to a domain and publish it. Usage: rake scholars:publish[1,2,3,3,false]"
  task :publish, [ :scholar_ids, :domain_id, :dry_run ] => :environment do |_t, args|
    scholar_ids = (args[:scholar_ids] || ENV["SCHOLAR_IDS"]).to_s.split(",").map(&:strip).map(&:to_i)
    domain_id   = (args[:domain_id] || ENV["DOMAIN_ID"] || 3).to_i
    dry_run     = (args[:dry_run] || ENV["DRY"] || "true") != "false"
    domain = Domain.find(domain_id)

    classes = [ Fatwa, Lecture, Series ]
    classes.each do |klass|
      klass.where(scholar_id: scholar_ids).find_each do |rec|
        rec.assign_to(domain) unless  dry_run
        if !rec.published?
          rec.update!(published: true, published_at: Time.current) unless dry_run
          if klass == Series
            rec.lessons.where(published: false).find_each do |lesson|
              lesson.update!(published: true, published_at: Time.current) unless dry_run
            end
          end
        end
      end
    end

    puts "Done — dry_run: #{dry_run}"
  end

  desc "Fix doubled/UUID slugs and merge duplicate Scholar 1 into Scholar 2"
  task fix_slugs: :environment do
    ActiveRecord::Base.transaction do
      # Merge Scholar 1 (ibn-ramzan, empty) into Scholar 2 (محمد بن رمزان الهاجري)
      duplicate = Scholar.find_by(id: 1, slug: "ibn-ramzan")
      canonical = Scholar.find_by(id: 2)
      if duplicate && canonical && duplicate.full_name.blank?
        FriendlyId::Slug.where(sluggable_id: duplicate.id, sluggable_type: "Scholar")
                        .update_all(sluggable_id: canonical.id)
        duplicate.delete
        puts "Merged Scholar ##{duplicate.id} into Scholar ##{canonical.id}"
      end

      # Detect doubled slugs (e.g., "name-name") and UUID slugs
      uuid_re = /\A[0-9a-f]{8}-[0-9a-f]{4}-/
      bad_scholars = Scholar.all.select do |s|
        next false if s.slug.blank?
        parts = s.slug.split("-")
        half = parts.length / 2
        doubled = half > 0 && parts[0...half] == parts[half..]
        doubled || s.slug.match?(uuid_re)
      end

      puts "Found #{bad_scholars.size} scholars with bad slugs"

      bad_scholars.each do |scholar|
        old_slug = scholar.slug
        scholar.slug = nil
        scholar.save!
        puts "  #{old_slug} → #{scholar.slug}"
      end
    end

    puts "Done. Total scholars: #{Scholar.count}"
  end
end
