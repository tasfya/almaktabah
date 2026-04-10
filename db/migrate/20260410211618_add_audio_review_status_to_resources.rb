class AddAudioReviewStatusToResources < ActiveRecord::Migration[8.0]
  def change
    add_column :lessons, :audio_review_status, :integer, default: 0, null: false
    add_column :fatwas, :audio_review_status, :integer, default: 0, null: false
    add_column :lectures, :audio_review_status, :integer, default: 0, null: false
  end
end
