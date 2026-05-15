class AddPodcastFieldsToDomains < ActiveRecord::Migration[8.0]
  def change
    add_column :domains, :podcast_title, :string
    add_column :domains, :podcast_author, :string
    add_column :domains, :podcast_description, :text
    add_column :domains, :podcast_owner_name, :string
    add_column :domains, :podcast_owner_email, :string
    add_column :domains, :podcast_language, :string, default: "ar"
    add_column :domains, :podcast_category, :string, default: "Religion & Spirituality"
    add_column :domains, :podcast_subcategory, :string, default: "Islam"
    add_column :domains, :podcast_enabled, :boolean, default: false, null: false
  end
end
