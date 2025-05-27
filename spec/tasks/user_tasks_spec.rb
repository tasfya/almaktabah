require 'rails_helper'
require 'rake'

RSpec.describe "User rake tasks", type: :task do
  before :all do
    Rake.application.rake_require "tasks/users"
    Rake::Task.define_task(:environment)
  end

  describe "users:make_admin" do
    let!(:user) { create(:user, email: "test@example.com", admin: false) }
    let(:task) { Rake::Task["users:make_admin"] }

    before do
      task.reenable
    end

    it "promotes a user to admin" do
      expect(user.admin?).to be false
      
      # Capture output for verification
      output = capture_stdout do
        task.invoke("test@example.com")
      end
      
      # Reload user to get fresh data
      user.reload
      
      expect(user.admin?).to be true
      expect(output).to include("User test@example.com has been promoted to admin")
    end

    it "reports when user is already an admin" do
      user.update(admin: true)
      
      output = capture_stdout do
        task.reenable
        task.invoke("test@example.com")
      end
      
      expect(output).to include("User test@example.com is already an admin")
    end

    it "reports when user is not found" do
      output = capture_stdout do
        task.reenable
        task.invoke("nonexistent@example.com")
      end
      
      expect(output).to include("User with email nonexistent@example.com not found")
    end
  end

  describe "users:list_admins" do
    let!(:admin1) { create(:user, email: "admin1@example.com", admin: true) }
    let!(:admin2) { create(:user, email: "admin2@example.com", admin: true) }
    let!(:regular_user) { create(:user, email: "regular@example.com", admin: false) }
    let(:task) { Rake::Task["users:list_admins"] }

    before do
      task.reenable
    end

    it "lists all admin users" do
      output = capture_stdout do
        task.invoke
      end
      
      expect(output).to include("admin1@example.com")
      expect(output).to include("admin2@example.com")
      expect(output).not_to include("regular@example.com")
    end

    it "reports when no admin users exist" do
      User.update_all(admin: false)
      
      output = capture_stdout do
        task.reenable
        task.invoke
      end
      
      expect(output).to include("No admin users found")
    end
  end

  # Helper method to capture stdout
  def capture_stdout
    original_stdout = $stdout
    $stdout = StringIO.new
    yield
    $stdout.string
  ensure
    $stdout = original_stdout
  end
end
