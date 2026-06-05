class AddAudioVerifiedAtToModels < ActiveRecord::Migration[8.0]
  def change
    add_column :lectures, :audio_verified_at, :datetime
    add_column :lessons, :audio_verified_at, :datetime
    add_column :fatwas, :audio_verified_at, :datetime

    add_index :lectures, :audio_verified_at
    add_index :lessons, :audio_verified_at
    add_index :fatwas, :audio_verified_at
  end
end
