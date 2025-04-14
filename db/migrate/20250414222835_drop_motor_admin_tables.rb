class DropMotorAdminTables < ActiveRecord::Migration[8.0]
  def change
    drop_table :motor_alert_locks
    drop_table :motor_alerts
    drop_table :motor_api_configs
    drop_table :motor_audits
    drop_table :motor_configs
    drop_table :motor_dashboards
    drop_table :motor_forms
    drop_table :motor_note_tag_tags
    drop_table :motor_note_tags
    drop_table :motor_notes
    drop_table :motor_notifications
    drop_table :motor_queries
    drop_table :motor_reminders
  end
end
