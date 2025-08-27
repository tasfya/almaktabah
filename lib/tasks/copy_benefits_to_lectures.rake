namespace :copy_benefits_to_lectures do
  desc "Safely copy benefits to lectures"
  task perform: :environment do
    puts "Starting copy of Benefits to Lectures..."

    Benefit.find_each do |benefit|
      ActiveRecord::Base.transaction do
        puts "Copying Benefit ID #{benefit.id} - #{benefit.title}"

        lecture = Lecture.new(
          title:        benefit.title,
          duration:     benefit.duration,
          category:     benefit.category,
          kind:         :benefit,
          scholar_id:   benefit.scholar_id,
          published:    benefit.published,
          published_at: benefit.published_at,
        )

        unless lecture.save
          Rails.logger.error "Failed to save Benefit ID #{benefit.id} -> Lecture errors: #{lecture.errors.full_messages.join(", ")}"
          raise ActiveRecord::Rollback
        end

        if benefit.domains.any?
          benefit.domains.each do |domain|
            lecture.assign_to(domain)
          end
        end

        lecture.audio.attach(benefit.audio.blob) if benefit.audio.attached?
        lecture.thumbnail.attach(benefit.thumbnail.blob) if benefit.thumbnail.attached?
        lecture.video.attach(benefit.video.blob) if benefit.video.attached?

        AudioOptimizationJob.perform_later(lecture) if lecture.audio.attached?
      rescue => e
        Rails.logger.error "Exception while copying Benefit ID #{benefit.id}: #{e.class} - #{e.message}"
        raise ActiveRecord::Rollback
      end
    end

    puts "Copy finished."
  end
end
