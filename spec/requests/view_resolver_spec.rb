# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Per-domain view templates", type: :request do
  let!(:domain) { create(:domain, host: "localhost") }
  let(:templates_root) { Rails.root.join("app", "views", "templates") }

  before { host! "localhost" }

  def default_view_paths
    ApplicationController.view_paths.map(&:path)
  end

  context "when template_name is 'default'" do
    before { domain.update_column(:template_name, "default") }

    it "does not prepend a view path" do
      get about_path
      expect(controller.view_paths.map(&:path)).to eq(default_view_paths)
    end
  end

  context "when template_name is custom and its folder exists" do
    # Unique per example: ActionView caches a resolver per view path.
    let(:template_name) { "spec_theme_#{SecureRandom.hex(4)}" }
    let(:template_dir) { templates_root.join(template_name) }

    around do |example|
      FileUtils.mkdir_p(template_dir.join("about"))
      File.write(template_dir.join("about", "index.html.erb"), "<p>CUSTOM-THEME-ABOUT</p>")
      example.run
    ensure
      FileUtils.rm_rf(template_dir)
      FileUtils.rmdir(templates_root) if Dir.exist?(templates_root) && Dir.empty?(templates_root)
    end

    before { domain.update_column(:template_name, template_name) }

    it "renders the domain's template over the default one" do
      get about_path
      expect(controller.view_paths.map(&:path).first).to eq(template_dir.to_s)
      expect(response.body).to include("CUSTOM-THEME-ABOUT")
    end
  end

  context "when template_name is custom and its folder does not exist" do
    before { domain.update_column(:template_name, "missing_theme") }

    it "does not change view paths" do
      get about_path
      expect(controller.view_paths.map(&:path)).to eq(default_view_paths)
    end
  end
end
