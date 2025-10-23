namespace :typesense do
  desc "Populate Typesense data for all indexed models or specific models"
  task :populate, [ :models ] => :environment do |t, args|
    models_to_index = if args[:models].present?
                        args[:models].split(",").map(&:strip)
    else
                        # Default to all models that include Typesense
                        get_typesense_models
    end

    puts "Starting Typesense data population..."
    puts "Models to index: #{models_to_index.join(', ')}"

    models_to_index.each do |model_name|
      begin
        model_class = model_name.constantize

        unless model_class.include?(Typesense)
          puts "⚠️  Skipping #{model_name} - does not include Typesense module"
          next
        end

        puts "📝 Indexing #{model_name}..."

        # Use reindex! for immediate indexing (overwrites existing data)
        # Use reindex for zero-downtime indexing if you have a large dataset
        model_class.reindex!

        puts "✅ Successfully indexed #{model_name}"
      rescue NameError => e
        puts "❌ Error: Model #{model_name} not found - #{e.message}"
      rescue StandardError => e
        puts "❌ Error indexing #{model_name}: #{e.message}"
      end
    end

    puts "Typesense data population completed!"
  end

  desc "Delete all Typesense collections for all indexed models or specific models"
  task :delete_all, [ :models ] => :environment do |t, args|
    models_to_delete = if args[:models].present?
                         args[:models].split(",").map(&:strip)
    else
                         # Default to all models that include Typesense
                         get_typesense_models
    end

    puts "Starting Typesense collections deletion..."
    puts "Models to delete collections for: #{models_to_delete.join(', ')}"

    models_to_delete.each do |model_name|
      begin
        model_class = model_name.constantize

        unless model_class.include?(Typesense)
          puts "⚠️  Skipping #{model_name} - does not include Typesense module"
          next
        end

        puts "🗑️  Deleting collection for #{model_name}..."

        # Delete the Typesense collection
        collection_name = model_name.tableize
        Typesense.client.collections[collection_name].delete

        puts "✅ Successfully deleted collection for #{model_name}"
      rescue NameError => e
        puts "❌ Error: Model #{model_name} not found - #{e.message}"
      rescue StandardError => e
        puts "❌ Error deleting collection for #{model_name}: #{e.message}"
      end
    end

    puts "Typesense collections deletion completed!"
  end

  desc "List all models that include Typesense"
  task list_models: :environment do
    models = get_typesense_models
    if models.empty?
      puts "No models found that include Typesense"
    else
      puts "Models with Typesense indexing:"
      models.each { |model| puts "  - #{model}" }
    end
  end
end

def get_typesense_models
  # Get all models that include the Typesense module
  models = []
  Rails.application.eager_load!

  ApplicationRecord.descendants.each do |model|
    models << model.name if model.include?(Typesense)
  end

  models.sort
end
