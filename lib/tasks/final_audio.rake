namespace :audio do
  desc "Enqueue FinalAudioCopyJob for records with optimized audio. Usage: rake audio:enqueue_final_copy[all,false]"
  task :enqueue_final_copy, [ :model, :force ] => :environment do |_, args|
    force = args[:force] == "true"
    model_arg = args[:model].presence || "all"

    available_models = {
      "Lesson" => Lesson,
      "Lecture" => Lecture,
      "Fatwa" => Fatwa
    }

    models =
      if model_arg == "all"
        available_models.values
      else
        requested = model_arg.split(",").map(&:strip)
        unknown = requested - available_models.keys

        if unknown.any?
          puts "Unknown model(s): #{unknown.join(", ")}"
          puts "Available models: #{available_models.keys.join(", ")}"
          exit(1)
        end

        requested.map { |name| available_models.fetch(name) }
      end

    models.each do |model|
      scope = model.joins(:optimized_audio_attachment)
      scope = scope.where.missing(:final_audio_attachment) unless force

      count = scope.count
      puts "Enqueuing #{count} #{model.name} record(s) (force: #{force})..."

      scope.find_each do |record|
        FinalAudioCopyJob.perform_later(record, force: force)
      end
    end
  end
end
