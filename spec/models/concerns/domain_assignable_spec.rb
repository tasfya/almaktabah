require "rails_helper"

RSpec.describe DomainAssignable do
  let!(:global_default) { create(:domain, is_default: true) }
  let(:scholar_site) { create(:domain) }
  let(:scholar) { create(:scholar, default_domain: scholar_site) }

  {
    lesson: -> { { series: create(:series, scholar: scholar) } },
    series: -> { { scholar: scholar } },
    book: -> { { scholar: scholar } },
    article: -> { { scholar: scholar } },
    lecture: -> { { scholar: scholar } },
    fatwa: -> { { scholar: scholar } },
    news: -> { { scholar: scholar } }
  }.each do |factory, attributes|
    it "assigns a #{factory} to its scholar's default domain and the global default" do
      record = build(factory, **instance_exec(&attributes))
      record.save!
      expect(record.reload.domains).to include(scholar_site, global_default)
    end
  end

  it "assigns a model without a scholar to the global default only" do
    expect(create(:program).domains).to eq([ global_default ])
  end
end
