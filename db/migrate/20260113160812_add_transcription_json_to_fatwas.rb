class AddTranscriptionJsonToFatwas < ActiveRecord::Migration[8.0]
  def change
    add_column :fatwas, :transcription_json, :text
  end
end
