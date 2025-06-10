class AddVideoUrlToLectures < ActiveRecord::Migration[8.0]
  def change
    add_column :lectures, :video_url, :string
  end
end
