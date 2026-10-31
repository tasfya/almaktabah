# frozen_string_literal: true

require "rails_helper"

# The share button opens a <dialog> whose share-modal controller copies the
# page link and builds the social share URLs. window.open is replaced with a
# recorder so no external site is ever opened.
RSpec.describe "Share modal", type: :system, js: true do
  let!(:domain) { create(:domain, host: "127.0.0.1") }
  let(:scholar) { create(:scholar, full_name: "Abdul Aziz") }
  let!(:article) do
    create(:article, title: "Shared Article", scholar: scholar).tap { |a| a.update!(domains: [ domain ]) }
  end

  let(:dialog) { "dialog#article_share_modal" }

  def open_share_modal
    visit article_path(scholar, article)
    find("[data-controller='share-trigger'][data-share-trigger-modal-id-value='article_share_modal']").click
    expect(page).to have_css("#{dialog}[open]")
  end

  def record_window_open
    page.execute_script("window.__opened = []; window.open = (url, ...rest) => { window.__opened.push([url, ...rest]) }")
  end

  def opened = page.evaluate_script("window.__opened")

  it "opens on the share button and shows the page link" do
    open_share_modal

    within(dialog) do
      expect(find("[data-share-modal-target='urlInput']").value).to eq(page.current_url)
    end
  end

  it "closes from its close button" do
    open_share_modal

    within(dialog) { find("form[method='dialog'] button").click }

    expect(page).to have_no_css("#{dialog}[open]")
  end

  it "confirms that the link was copied" do
    open_share_modal

    within(dialog) do
      expect(page).to have_no_text(I18n.t("common.copy_success"))
      find("[data-share-modal-target='copyButton']").click
      expect(page).to have_text(I18n.t("common.copy_success"))
    end
  end

  {
    "shareTwitter" => %r{\Ahttps://twitter\.com/intent/tweet\?text=.+&url=(?<url>[^&]+)\z},
    "shareFacebook" => %r{\Ahttps://www\.facebook\.com/sharer/sharer\.php\?u=(?<url>[^&]+)\z},
    "shareTelegram" => %r{\Ahttps://t\.me/share/url\?url=(?<url>[^&]+)&text=.+\z}
  }.each do |action, pattern|
    it "#{action} opens the share URL for this page in a new tab" do
      open_share_modal
      record_window_open

      within(dialog) { find("button[data-action='click->share-modal##{action}']").click }

      expect(opened.size).to eq(1)
      url, target, features = opened.first
      expect(url).to match(pattern)
      expect(CGI.unescape(url[pattern, :url])).to eq(page.current_url)
      expect([ target, features ]).to eq([ "_blank", "noopener,noreferrer" ])
    end
  end

  it "shareWhatsApp puts the title and page link in the message" do
    open_share_modal
    record_window_open

    within(dialog) { find("button[data-action='click->share-modal#shareWhatsApp']").click }

    url = opened.first.first
    expect(url).to start_with("https://wa.me/?text=")
    message = CGI.unescape(url.delete_prefix("https://wa.me/?text="))
    expect(message).to end_with(" #{page.current_url}")
  end
end
