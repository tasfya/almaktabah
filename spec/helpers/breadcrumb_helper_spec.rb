# spec/helpers/breadcrumb_helper_spec.rb
require 'rails_helper'

RSpec.describe BreadcrumbHelper, type: :controller do
  controller(ApplicationController) do
    include BreadcrumbHelper

    def index
      render plain: "OK"
    end
  end

  before do
    routes.draw { get "index" => "anonymous#index" }
    get :index
  end

  describe '#breadcrumb_for' do
    it 'adds a breadcrumb to the session' do
      expect {
        controller.breadcrumb_for("Dashboard", "/dashboard")
      }.to change { session[:breadcrumbs].length }.by(1)

      crumb = session[:breadcrumbs].last
      expect(crumb[:name]).to eq("Dashboard")
      expect(crumb[:path]).to eq("/dashboard")
    end

    it 'does not add duplicate breadcrumbs by name and path' do
      2.times { controller.breadcrumb_for("Dashboard", "/dashboard") }
      expect(session[:breadcrumbs].length).to eq(1)
    end

    it 'removes existing breadcrumb with same path before adding new one' do
      controller.breadcrumb_for("Old", "/dashboard")
      controller.breadcrumb_for("New", "/dashboard")
      expect(session[:breadcrumbs].length).to eq(1)
      expect(session[:breadcrumbs].first[:name]).to eq("New")
    end

    it 'limits breadcrumbs to last 8' do
      10.times { |i| controller.breadcrumb_for("Crumb#{i}", "/path#{i}") }
      expect(session[:breadcrumbs].length).to eq(8)
    end
  end

  describe '#reset_breadcrumbs' do
    it 'clears all breadcrumbs' do
      controller.breadcrumb_for("One", "/one")
      controller.reset_breadcrumbs
      expect(session[:breadcrumbs]).to eq([])
    end
  end

  describe '#current_breadcrumbs' do
    it 'prepends Home breadcrumb if missing' do
      controller.breadcrumb_for("Page", "/page")
      breadcrumbs = controller.current_breadcrumbs
      expect(breadcrumbs.first[:name]).to eq("الصفحة الرئيسية")
    end

    it 'does not prepend Home if already present' do
      allow(controller).to receive(:root_path).and_return("/home")
      controller.breadcrumb_for("الصفحة الرئيسية", "/home")
      controller.breadcrumb_for("Other", "/other")
      breadcrumbs = controller.current_breadcrumbs
      expect(breadcrumbs.select { |b| b[:path] == "/home" }.length).to eq(1)
    end
  end

  describe '#set_breadcrumb_limits' do
    it 'truncates breadcrumbs to the given limit' do
      5.times { |i| controller.breadcrumb_for("Crumb#{i}", "/path#{i}") }
      controller.set_breadcrumb_limits(3)
      expect(session[:breadcrumbs].length).to eq(3)
    end
  end

  describe '#current_page_in_breadcrumbs?' do
    it 'returns true if path exists' do
      controller.breadcrumb_for("Page", "/page")
      expect(controller.current_page_in_breadcrumbs?("/page")).to be true
    end

    it 'returns false if path does not exist' do
      expect(controller.current_page_in_breadcrumbs?("/none")).to be false
    end
  end

  describe '#find_breadcrumb_by_path' do
    it 'returns the breadcrumb with the matching path' do
      controller.breadcrumb_for("Target", "/target")
      result = controller.find_breadcrumb_by_path("/target")
      expect(result[:name]).to eq("Target")
    end
  end

  describe '#remove_breadcrumb' do
    it 'removes the breadcrumb with the given path' do
      controller.breadcrumb_for("Removable", "/remove")
      controller.remove_breadcrumb("/remove")
      expect(session[:breadcrumbs]).to be_empty
    end
  end

  describe '#add_breadcrumbs' do
    it 'adds multiple breadcrumbs from array and hash' do
      controller.add_breadcrumbs([ "Page1", "/page1" ], { name: "Page2", path: "/page2" })
      expect(session[:breadcrumbs].length).to eq(2)
      expect(session[:breadcrumbs].map { |b| b[:name] }).to include("Page1", "Page2")
    end
  end
end
