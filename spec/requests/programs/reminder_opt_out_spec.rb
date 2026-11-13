require "rails_helper"

RSpec.describe "Reminder opt-out", type: :request do
  include_context "with tenant domain"

  let(:enrollment) { create(:enrollment, domain: domain) }
  let(:token) { enrollment.generate_token_for(:reminders_off) }

  it "GET shows a confirm button and changes nothing" do
    get reminder_opt_out_path(token: token)

    expect(response).to have_http_status(:ok)
    expect(response.body).to include(enrollment.cohort.program.title)
    expect(enrollment.reload.reminders_enabled).to be(true)
  end

  it "POST without a session or CSRF token turns reminders off" do
    ActionController::Base.allow_forgery_protection = true
    post reminder_opt_out_path(token: token), params: { "List-Unsubscribe" => "One-Click" }

    expect(response).to have_http_status(:ok)
    expect(enrollment.reload.reminders_enabled).to be(false)
  ensure
    ActionController::Base.allow_forgery_protection = false
  end

  it "POST from a mail client without a browser user agent works" do
    post reminder_opt_out_path(token: token), headers: { "User-Agent" => "" }

    expect(response).to have_http_status(:ok)
    expect(enrollment.reload.reminders_enabled).to be(false)
  end

  it "works from an old browser that the rest of the site turns away" do
    old_chrome = "Mozilla/5.0 (Linux; Android 9) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.127 Mobile Safari/537.36"

    get reminder_opt_out_path(token: token), headers: { "User-Agent" => old_chrome }
    expect(response).to have_http_status(:ok)

    post reminder_opt_out_path(token: token), headers: { "User-Agent" => old_chrome }
    expect(response).to have_http_status(:ok)
    expect(enrollment.reload.reminders_enabled).to be(false)
  end

  it "GET says reminders are already off, with no button, when they are" do
    enrollment.update!(reminders_enabled: false)

    get reminder_opt_out_path(token: token)

    html = Nokogiri::HTML(response.body)
    expect(response.body).to include(I18n.t("programs.reminders.opt_out.already_off", program: enrollment.cohort.program.title))
    expect(html.at_css("form[action='#{reminder_opt_out_path(token: token)}']")).to be_nil
    expect(html.at_css("a[href='#{learner_account_path}']")).to be_present
  end

  it "POST links to the account page where reminders can be turned back on" do
    post reminder_opt_out_path(token: token)

    expect(Nokogiri::HTML(response.body).at_css("a[href='#{learner_account_path}']")).to be_present
  end

  it "returns not found for a tampered token" do
    get reminder_opt_out_path(token: "#{token}x")
    expect(response).to have_http_status(:not_found)

    post reminder_opt_out_path(token: "#{token}x")
    expect(response).to have_http_status(:not_found)
    expect(enrollment.reload.reminders_enabled).to be(true)
  end

  it "sends Cache-Control no-store" do
    get reminder_opt_out_path(token: token)

    expect(response.headers["Cache-Control"]).to include("no-store")
  end
end
