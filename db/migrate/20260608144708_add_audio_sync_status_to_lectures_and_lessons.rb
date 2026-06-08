class AddAudioSyncStatusToLecturesAndLessons < ActiveRecord::Migration[8.0]
  def change
    add_column :lectures, :audio_sync_status, :integer, default: 0
    add_column :lessons, :audio_sync_status, :integer, default: 0
  end
end
