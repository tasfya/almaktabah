require "rails_helper"

RSpec.describe VideoGenerationJob, type: :job do
  let(:generator) { instance_double(VideoGeneratorService, call: { success: false, error: "stop" }) }
  let(:lecture) { create(:lecture, video: nil) }

  before { allow(VideoGeneratorService).to receive(:new).and_return(generator) }

  it "renders no logo for a domain that has none, rather than another site's" do
    lecture.update!(domains: [ create(:domain) ])

    expect { described_class.perform_now(lecture) }.to raise_error(StandardError, "stop")
    expect(VideoGeneratorService).to have_received(:new).with(hash_including(logo_file: nil))
  end

  it "uses the domain's own logo when it has one" do
    domain = create(:domain)
    domain.logo.attach(io: Rails.root.join("spec/files/logo.png").open, filename: "logo.png", content_type: "image/png")
    lecture.update!(domains: [ domain ])

    expect { described_class.perform_now(lecture) }.to raise_error(StandardError, "stop")
    expect(VideoGeneratorService).to have_received(:new).with(hash_including(logo_file: domain.logo))
  end
end
