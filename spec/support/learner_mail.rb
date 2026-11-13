# frozen_string_literal: true

# Turns learner mail on (and redraws the routes that depend on it) for the
# examples in a group.
RSpec.shared_context "with learner mail on" do
  around do |example|
    Rails.configuration.x.learner_mail_enabled = true
    Rails.application.reload_routes!
    example.run
  ensure
    Rails.configuration.x.learner_mail_enabled = false
    Rails.application.reload_routes!
  end
end
