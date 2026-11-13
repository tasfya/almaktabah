# frozen_string_literal: true

require "rails_helper"

RSpec.describe Learners::MailIdentity do
  before { stub_const("ENV", ENV.to_h.merge("LEARNER_MAIL_DOMAINS" => "3ilm.org, binramzan.net")) }

  def identity(host, title: "موقع")
    described_class.new(build(:domain, host: host, title: title))
  end

  it "uses the parent zone for a subdomain tenant" do
    mail = identity("fawzan.3ilm.org", title: "الشيخ صالح بن فوزان الفوزان")

    expect(mail.from).to eq('"الشيخ صالح بن فوزان الفوزان" <no-reply@3ilm.org>')
    expect(mail.host).to eq("fawzan.3ilm.org")
  end

  it "keeps a site title with quotes whole" do
    mail = Mail::Address.new(identity("binramzan.net", title: 'موقع "الشيخ" العلمي').from)

    expect(mail.display_name).to eq('موقع "الشيخ" العلمي')
    expect(mail.address).to eq("no-reply@binramzan.net")
  end

  it "uses the site's own zone" do
    expect(identity("binramzan.net").from).to end_with("<no-reply@binramzan.net>")
  end

  it "falls back to the first verified zone" do
    mail = identity("suhai.me")

    expect(mail.from).to end_with("<no-reply@3ilm.org>")
    expect(mail.host).to eq("suhai.me")
  end

  it "links over https on the site host" do
    expect(identity("suhai.me").url_options).to include(host: "suhai.me", protocol: "https")
  end

  it "keeps the site's zone when no verified zone is configured" do
    stub_const("ENV", ENV.to_h.except("LEARNER_MAIL_DOMAINS"))

    expect(identity("suhai.me").from).to end_with("<no-reply@suhai.me>")
  end
end
