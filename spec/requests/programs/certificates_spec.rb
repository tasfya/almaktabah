require "rails_helper"

RSpec.describe "Certificate page", type: :request do
  include_context "with tenant domain"

  let(:program) { create(:program, title: "متون التوحيد", published: true).tap { |p| p.update!(domains: [ domain ]) } }
  let(:cohort) { create(:cohort, program: program, name: "١٤٤٧–١٤٤٨") }
  let(:learner) { create(:learner, full_name: "فاطمة بنت محمد", gender: :female) }
  let(:enrollment) { create(:enrollment, learner: learner, cohort: cohort, domain: domain) }
  let(:certificate) { create(:certificate, enrollment: enrollment, number: "7-ABCD1234") }

  # Literal path: the URL is printed on paper and must not move.
  let(:path) { "/#{URI::DEFAULT_PARSER.escape("الشهادات")}/7-ABCD1234" }

  it "shows the certificate with feminine wording from the snapshot" do
    certificate
    learner.update!(full_name: "اسم آخر", gender: :male)

    get path

    expect(response).to have_http_status(:ok)
    body = response.body
    expect(body).to include("فاطمة بنت محمد", "متون التوحيد", "١٤٤٧–١٤٤٨", "7-ABCD1234")
    expect(body).to include(I18n.t("programs.certificate.body.female.student"), I18n.t("programs.certificate.body.female.completed"))
    expect(body).not_to include("اسم آخر")
  end

  it "uses masculine wording for a male snapshot" do
    create(:certificate, enrollment: enrollment, number: "7-ABCD1234", gender_snapshot: "male")

    get path

    expect(response.body).to include(I18n.t("programs.certificate.body.male.completed"))
    expect(response.body).not_to include(I18n.t("programs.certificate.body.female.completed"))
  end

  it "is noindex and never publicly cached" do
    certificate

    get path

    expect(response.body).to include('<meta name="robots" content="noindex, nofollow">')
    expect(response.headers["Cache-Control"]).to include("no-store")
    expect(response.headers["Cache-Control"]).not_to include("public")
  end

  it "is not found on another domain" do
    create(:certificate, enrollment: create(:enrollment, cohort: cohort, domain: other_domain), number: "7-ABCD1234")

    get path

    expect(response).to have_http_status(:not_found)
    expect(response.headers["Cache-Control"]).to include("no-store")
  end

  it "is not found for an unknown number" do
    get path

    expect(response).to have_http_status(:not_found)
  end

  it "marks a revoked certificate as revoked without showing the name" do
    certificate.update!(revoked_at: Time.current)

    get path

    expect(response).to have_http_status(:ok)
    expect(response.body).to include(I18n.t("programs.certificate.revoked_title"), "7-ABCD1234")
    expect(response.body).not_to include("فاطمة بنت محمد")
    expect(response.headers["Cache-Control"]).to include("no-store")
  end

  it "shows a certificate whose account was deleted as revoked" do
    certificate
    learner.destroy!

    get path

    expect(response).to have_http_status(:ok)
    expect(response.body).to include(I18n.t("programs.certificate.revoked_title"))
    expect(response.body).not_to include("فاطمة بنت محمد")
  end

  it "dates the certificate in the cohort's time zone, not UTC" do
    cohort.update!(time_zone: "Asia/Riyadh")
    certificate.update!(issued_at: Time.utc(2026, 11, 13, 22, 15))

    get path

    expect(response.body).to include(I18n.l(Date.new(2026, 11, 14), format: :long))
    expect(response.body).not_to include(I18n.l(Date.new(2026, 11, 13), format: :long))
  end

  it "finds the certificate whatever the case the number is typed in" do
    certificate

    get path.sub("7-ABCD1234", "7-abcd1234")

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("فاطمة بنت محمد")
  end

  it "links the verify URL without invisible direction marks" do
    certificate

    get path

    url = "http://#{domain.host}#{path}"
    link = Nokogiri::HTML(response.body).at_css("a[href='#{url}']")
    expect(link).to be_present
    expect(link.text.strip).to eq(CGI.unescape(url))
    expect(response.body).not_to include("\u200E")
  end

  it "does not repeat the word برنامج when the title starts with it" do
    program.update!(title: "برنامج تجريبي: التوحيد")
    certificate

    get path

    text = Nokogiri::HTML(response.body).at_css(".certificate-sheet").text.squish
    expect(text).to include("قد أتمّت دراسة «برنامج تجريبي: التوحيد»")
  end

  it "names the program with the word برنامج when the title lacks it" do
    certificate

    get path

    text = Nokogiri::HTML(response.body).at_css(".certificate-sheet").text.squish
    expect(text).to include("قد أتمّت دراسة برنامج «متون التوحيد»")
  end

  it "says the certificate is issued by the site" do
    certificate

    get path

    expect(response.body).to include("صادرة عن موقع")
  end

  describe "link from the cohort page" do
    include Devise::Test::IntegrationHelpers

    before { sign_in learner }

    it "links to the certificate on this site" do
      certificate

      get learner_cohort_path(cohort)

      expect(response.body).to include(%(href="#{path}"))
    end

    it "links to the issuing site when the learner enrolled on another site sharing the program" do
      program.update!(domains: [ domain, other_domain ])
      enrollment.update!(domain: other_domain)
      create(:certificate, enrollment: enrollment, domain: other_domain, number: "7-ABCD1234")

      get learner_cohort_path(cohort)

      expect(response.body).to include(%(href="http://other.example.com#{path}"))
    end
  end

  it "is not routed while learners are disabled" do
    certificate
    allow(Rails.configuration.x).to receive(:learners_enabled).and_return(false)

    get path

    expect(response).to have_http_status(:not_found)
  end
end
