# frozen_string_literal: true

require "rails_helper"

# Snapshot of the public routes table in definition order (order decides which
# route wins). Admin (Avo), Devise, the jobs dashboard and Rails' internal
# routes are left out, as are routes injected by gems (rails_icons,
# view_component's test entrypoint). Development-only routes
# (theme-playground) are absent because the snapshot runs in the test env.
#
# Regenerate after an intended routing change with
#   UPDATE_GOLDEN=1 bin/worktree test spec/routing/public_routes_spec.rb
RSpec.describe "Public routes table" do
  def public_routes
    Rails.application.routes.routes.filter_map do |route|
      wrapper = ActionDispatch::Routing::RouteWrapper.new(route)
      next if wrapper.internal? || wrapper.engine?
      next if wrapper.controller.to_s.match?(%r{\A(avo|devise|mission_control|active_storage|action_mailbox|rails/conductor|turbo|rails_icons|view_components)})

      target = wrapper.controller ? "#{wrapper.controller}##{wrapper.action}" : "redirect"
      requirements = route.requirements.except(:controller, :action).transform_values { |v| v.is_a?(Regexp) ? v.source : v }
      [ wrapper.verb.presence || "ANY", wrapper.path, target, *requirements.sort.map { |key, value| "#{key}=#{value}" } ].compact.join(" ")
    end
  end

  it "matches the committed snapshot" do
    expect(public_routes.join("\n") + "\n").to match_golden("routes/public.txt")
  end
end
