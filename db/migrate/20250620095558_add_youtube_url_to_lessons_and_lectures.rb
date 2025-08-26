class AddYoutubeUrlToLessonsAndLectures < ActiveRecord::Migration[8.0]
  def up
    add_column :lessons, :youtube_url, :string
    add_column :lectures, :youtube_url, :string
  end

  def down
    remove_column :lessons, :youtube_url
    remove_column :lectures, :youtube_url
  end
end
