class AddPodcastArtworkUrlToDomains < ActiveRecord::Migration[8.0]
  def change
    add_column :domains, :podcast_artwork_url_override, :string
  end
end
