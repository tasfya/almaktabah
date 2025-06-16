Rails.application.config.solid_queue.connect_to(
  database_configuration: Rails.application.config.database_configuration[Rails.env]["queue"]
)
