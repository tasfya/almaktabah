class UpdateLessonsFields < ActiveRecord::Migration[8.0]
  def change
    change_column_null :lessons, :title, false, 'Untitled Lesson'

    # Add any new fields or indexes that might be missing
    unless column_exists?(:lessons, :content_type)
      add_column :lessons, :content_type, :string, default: 'audio'
    end

    unless column_exists?(:lessons, :view_count)
      add_column :lessons, :view_count, :integer, default: 0
    end
  end
end
