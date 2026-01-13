class AddTranscriptionJsonToLectures < ActiveRecord::Migration[8.0]
  def change
    add_column :lectures, :transcription_json, :text
  end
end
