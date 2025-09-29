class Avo::Actions::GenerateVideo < Avo::BaseAction
  self.name = "Generate Video"

  def fields
    # No additional fields needed - we'll use the record's existing data
  end

  def handle(**args)
    records = args[:records]
    queued_count = 0
    failed_records = []
    records.each do |record|
      begin
        # Check if record has audio
        unless record.respond_to?(:audio?) && record.audio?
          failed_records << "#{record.class.name} ##{record.id}: No audio file attached"
          next
        end

        # Check if already has generated video
        if record.respond_to?(:generated_video?) && record.generated_video?
          failed_records << "#{record.class.name} ##{record.id}: Video already generated"
          next
        end

        # Queue the video generation job
        VideoGenerationJob.perform_later(record)
        queued_count += 1

      rescue => e
        failed_records << "#{record.class.name} ##{record.id}: #{e.message}"
      end
    end

    if queued_count > 0 && failed_records.empty?
      succeed "Successfully queued video generation for #{queued_count} record(s). Videos will be generated in the background."
    elsif queued_count > 0 && failed_records.any?
      succeed "Queued video generation for #{queued_count} record(s). Failed to queue: #{failed_records.join(', ')}"
    else
      error "Failed to queue video generation jobs. Errors: #{failed_records.join(', ')}"
    end
  end

  private

  def find_record_by_id(record_id)
    # Try to find the record in each model that includes MediaHandler
    [ Fatwa, Lecture, Lesson ].each do |model_class|
      record = model_class.find_by(id: record_id)
      return record if record
    end
    nil
  end
end
