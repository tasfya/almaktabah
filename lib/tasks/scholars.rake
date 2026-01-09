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
end
