# frozen_string_literal: true

require "rails_helper"

RSpec.describe Learners::Mailer do
  include_context "with learner mail on"

  before { stub_const("ENV", ENV.to_h.merge("LEARNER_MAIL_DOMAINS" => "3ilm.org,binramzan.net")) }

  let(:fawzan) { create(:domain, host: "fawzan.3ilm.org", title: "الشيخ صالح بن فوزان الفوزان") }
  let(:binramzan) { create(:domain, host: "binramzan.net", title: "موقع الشيخ") }
  let(:learner) { create(:learner, full_name: "فاطمة بنت أحمد", domain: fawzan) }

  it "sends confirmation from the sign-up site with links to its host" do
    mail = described_class.confirmation_instructions(learner, "tok123")

    expect(mail.from).to eq([ "no-reply@3ilm.org" ])
    expect(mail[:from].display_names).to eq([ "الشيخ صالح بن فوزان الفوزان" ])
    expect(mail.reply_to).to be_nil
    expect(mail.html_part.body.to_s).to include("https://fawzan.3ilm.org/learners/confirmation?confirmation_token=tok123")
    expect(mail.text_part.body.to_s).to include("https://fawzan.3ilm.org/learners/confirmation?confirmation_token=tok123")
  end

  it "sends reset password from the site the request came from" do
    mail = described_class.reset_password_instructions(learner, "tok456", domain_id: binramzan.id)

    expect(mail.from).to eq([ "no-reply@binramzan.net" ])
    expect(mail.html_part.body.to_s).to include("https://binramzan.net/learners/password/edit?reset_password_token=tok456")
  end

  it "links to the given request host in development" do
    mail = described_class.reset_password_instructions(learner, "tok", url_options: { host: "almaktabah-x.localhost", port: 1355, protocol: "http://" })

    expect(mail.text_part.body.to_s).to include("http://almaktabah-x.localhost:1355/learners/password/edit?reset_password_token=tok")
    expect(mail.from).to eq([ "no-reply@3ilm.org" ])
  end

  it "is Arabic RTL with a text part" do
    mail = described_class.reset_password_instructions(learner, "tok", {})

    expect(mail.html_part.body.to_s).to include('dir="rtl"', 'lang="ar"')
    expect(mail.text_part).to be_present
    expect(mail.subject).to eq(I18n.t("devise.mailer.reset_password_instructions.subject", locale: :ar))
  end

  it "greets the learner by full name" do
    mail = described_class.confirmation_instructions(learner, "tok")

    expect(mail.text_part.body.to_s).to include("فاطمة بنت أحمد")
  end
end
