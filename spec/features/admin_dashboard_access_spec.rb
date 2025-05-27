require 'rails_helper'

# Skip these tests if Capybara is not available
RSpec.describe "Admin Dashboard Access", type: :feature, if: defined?(Capybara) do
  context "when user is not logged in" do
    it "redirects to login page when trying to access the admin area" do
      visit "/avo"
      expect(page).to have_current_path(new_user_session_path)
    end
  end

  context "when user is logged in but not an admin" do
    before do
      user = create(:user, email: "user@example.com", password: "password", password_confirmation: "password", admin: false)
      visit new_user_session_path
      fill_in "Email", with: user.email
      fill_in "Password", with: "password"
      click_button "Log in"
    end

    it "shows an access denied message when trying to access the admin area" do
      visit "/avo"
      expect(page).to have_current_path(root_path)
      expect(page).to have_content("You must be an admin user to access this section")
    end
  end

  context "when user is an admin" do
    before do
      admin = create(:user, email: "admin@example.com", password: "password", password_confirmation: "password", admin: true)
      visit new_user_session_path
      fill_in "Email", with: admin.email
      fill_in "Password", with: "password"
      click_button "Log in"
    end

    it "allows access to the admin area" do
      visit "/avo"
      expect(page).to have_current_path("/avo")
      expect(page).not_to have_content("You must be an admin user to access this section")
    end
  end
end
