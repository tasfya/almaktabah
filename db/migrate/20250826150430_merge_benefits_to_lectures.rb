class MergeBenefitsToLectures < ActiveRecord::Migration[8.0]
  def up
    # Copy all benefits data to lectures table with kind = 3 (benefit)
    execute <<-SQL
      INSERT INTO lectures (
        title, description, category, duration, published_at,#{' '}
        created_at, updated_at, published, scholar_id, kind
      )
      SELECT#{' '}
        title, description, category, duration, published_at,
        created_at, updated_at, published, scholar_id, 3 as kind
      FROM benefits;
    SQL

    # Copy Active Storage attachments from benefits to lectures
    # Update audio attachments
    execute <<-SQL
      UPDATE active_storage_attachments#{' '}
      SET record_type = 'Lecture',#{' '}
          record_id = (
            SELECT l.id FROM lectures l#{' '}
            INNER JOIN benefits b ON l.title = b.title AND l.created_at = b.created_at
            WHERE b.id = active_storage_attachments.record_id
          )
      WHERE record_type = 'Benefit' AND name = 'audio';
    SQL

    # Update video attachments
    execute <<-SQL
      UPDATE active_storage_attachments#{' '}
      SET record_type = 'Lecture',#{' '}
          record_id = (
            SELECT l.id FROM lectures l#{' '}
            INNER JOIN benefits b ON l.title = b.title AND l.created_at = b.created_at
            WHERE b.id = active_storage_attachments.record_id
          )
      WHERE record_type = 'Benefit' AND name = 'video';
    SQL

    # Update thumbnail attachments
    execute <<-SQL
      UPDATE active_storage_attachments#{' '}
      SET record_type = 'Lecture',#{' '}
          record_id = (
            SELECT l.id FROM lectures l#{' '}
            INNER JOIN benefits b ON l.title = b.title AND l.created_at = b.created_at
            WHERE b.id = active_storage_attachments.record_id
          )
      WHERE record_type = 'Benefit' AND name = 'thumbnail';
    SQL

    # Update optimized_audio attachments
    execute <<-SQL
      UPDATE active_storage_attachments#{' '}
      SET record_type = 'Lecture',#{' '}
          record_id = (
            SELECT l.id FROM lectures l#{' '}
            INNER JOIN benefits b ON l.title = b.title AND l.created_at = b.created_at
            WHERE b.id = active_storage_attachments.record_id
          )
      WHERE record_type = 'Benefit' AND name = 'optimized_audio';
    SQL

    # Update ActionText rich text content
    execute <<-SQL
      UPDATE action_text_rich_texts#{' '}
      SET record_type = 'Lecture',#{' '}
          record_id = (
            SELECT l.id FROM lectures l#{' '}
            INNER JOIN benefits b ON l.title = b.title AND l.created_at = b.created_at
            WHERE b.id = action_text_rich_texts.record_id
          )
      WHERE record_type = 'Benefit';
    SQL

    # Update domain assignments
    execute <<-SQL
      UPDATE domain_assignments#{' '}
      SET assignable_type = 'Lecture',#{' '}
          assignable_id = (
            SELECT l.id FROM lectures l#{' '}
            INNER JOIN benefits b ON l.title = b.title AND l.created_at = b.created_at
            WHERE b.id = domain_assignments.assignable_id
          )
      WHERE assignable_type = 'Benefit';
    SQL
  end

  def down
    # Remove merged benefits (those with kind = 3)
    lecture_ids = execute("SELECT id FROM lectures WHERE kind = 3").to_a.map { |row| row['id'] }

    if lecture_ids.any?
      # Restore domain assignments
      execute <<-SQL
        UPDATE domain_assignments#{' '}
        SET assignable_type = 'Benefit'
        WHERE assignable_type = 'Lecture' AND assignable_id IN (#{lecture_ids.join(',')});
      SQL

      # Restore ActionText rich text content
      execute <<-SQL
        UPDATE action_text_rich_texts#{' '}
        SET record_type = 'Benefit'
        WHERE record_type = 'Lecture' AND record_id IN (#{lecture_ids.join(',')});
      SQL

      # Restore Active Storage attachments
      execute <<-SQL
        UPDATE active_storage_attachments#{' '}
        SET record_type = 'Benefit'
        WHERE record_type = 'Lecture' AND record_id IN (#{lecture_ids.join(',')});
      SQL

      # Move lectures with kind = 3 back to benefits table
      execute <<-SQL
        INSERT INTO benefits (
          title, description, category, duration, published_at,#{' '}
          created_at, updated_at, published, scholar_id
        )
        SELECT#{' '}
          title, description, category, duration, published_at,
          created_at, updated_at, published, scholar_id
        FROM lectures WHERE kind = 3;
      SQL

      # Remove the merged lectures
      execute "DELETE FROM lectures WHERE kind = 3;"
    end
  end
end
