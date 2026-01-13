class AddTranscriptionJsonToLessons < ActiveRecord::Migration[8.0]
  def change
    add_column :lessons, :transcription_json, :text
  end
end
