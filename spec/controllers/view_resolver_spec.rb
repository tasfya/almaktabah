require "rails_helper"

RSpec.describe "ViewResolver", type: :controller do
  let!(:domain) { create(:domain, host: "localhost") }

  before do
    request.host = "localhost"
  end
  controller(ApplicationController) do
    include ViewResolver

    def index
      render plain: "ok"
    end
  end

  context "when template_name is 'default'" do
    before do
      domain.update_column(:template_name, "default")
    end

    it "does not prepend a new view path" do
      old_paths = controller.view_paths.map(&:path)
      get :index
      expect(controller.view_paths.map(&:path)).to eq(old_paths)
    end
  end

  context "when template_name is custom and folder exists" do
    before do
      domain.update_column(:template_name, "custom_theme")
    end

    before do
      allow(Dir).to receive(:exist?)
        .with(Rails.root.join("app", "views", "templates", "custom_theme"))
        .and_return(true)
    end

    it "prepends the custom template path" do
      get :index
      expect(controller.view_paths.map(&:path).first)
        .to eq(Rails.root.join("app", "views", "templates", "custom_theme").to_s)
    end
  end

  context "when template_name is custom and folder does not exist" do
    before do
      domain.update_column(:template_name, "missing_theme")
      allow(Dir).to receive(:exist?).and_return(false)
    end

    it "does not change view paths" do
      old_paths = controller.view_paths.map(&:path)
      get :index
      expect(controller.view_paths.map(&:path)).to eq(old_paths)
    end
  end
end
