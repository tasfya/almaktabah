class AddSocialLinksToDomains < ActiveRecord::Migration[8.1]
  def up
    add_column :domains, :youtube_url, :string
    add_column :domains, :x_url, :string

    # These links used to be hard-coded in the shared footer for every site.
    execute <<~SQL
      UPDATE domains
      SET youtube_url = 'https://www.youtube.com/@bin-ramzan',
          x_url = 'https://x.com/Moh1Rz2H3?ref'
      WHERE host = 'binramzan.net'
    SQL
  end

  def down
    remove_column :domains, :x_url
    remove_column :domains, :youtube_url
  end
end
