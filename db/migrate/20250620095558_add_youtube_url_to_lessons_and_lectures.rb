class AddYoutubeUrlToLessonsAndLectures < ActiveRecord::Migration[8.0]
  def up
    add_column :lessons, :youtube_url, :string
    add_column :lectures, :youtube_url, :string

    # Move YouTube URLs from video_url to youtube_url using SQL
    execute <<-SQL
      UPDATE lessons
      SET youtube_url = video_url,
          video_url = NULL
      WHERE video_url IS NOT NULL
        AND (video_url LIKE '%youtube.com%' OR video_url LIKE '%youtu.be%');
    SQL

    execute <<-SQL
      UPDATE lectures
      SET youtube_url = video_url,
          video_url = NULL
      WHERE video_url IS NOT NULL
        AND (video_url LIKE '%youtube.com%' OR video_url LIKE '%youtu.be%');
    SQL
  end

  def down
    # Move YouTube URLs back to video_url using SQL
    execute <<-SQL
      UPDATE lessons
      SET video_url = youtube_url,
          youtube_url = NULL
      WHERE youtube_url IS NOT NULL;
    SQL

    execute <<-SQL
      UPDATE lectures
      SET video_url = youtube_url,
          youtube_url = NULL
      WHERE youtube_url IS NOT NULL;
    SQL

    remove_column :lessons, :youtube_url
    remove_column :lectures, :youtube_url
  end
end
