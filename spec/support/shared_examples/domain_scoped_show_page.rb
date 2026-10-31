# frozen_string_literal: true

# A public page serves a record only when it is published and assigned to the
# requesting domain; otherwise it redirects to +not_found_path+ with the
# +not_found+ flash message (an I18n key).
#
# Needs `domain` and `other_domain` (the "with tenant domain" context).
#
#   it_behaves_like "a domain-scoped show page",
#     record: ->(published:) { create(:article, scholar: scholar, published: published, published_at: (1.day.ago if published)) },
#     path: ->(article) { article_path(article.scholar, article) },
#     not_found_path: -> { articles_path },
#     not_found: "messages.article_not_found"
RSpec.shared_examples "a domain-scoped show page" do |record:, path:, not_found_path:, not_found:|
  def record_on(target_domain, published:)
    instance_exec(published: published, &scoped_record_factory).tap do |r|
      r.domains = [ target_domain ]
      r.save!
    end
  end

  let(:scoped_record_factory) { record }

  it "serves a published record assigned to this domain" do
    get instance_exec(record_on(domain, published: true), &path)
    expect(response).to have_http_status(:ok)
  end

  it "does not serve a published record assigned only to another domain" do
    get instance_exec(record_on(other_domain, published: true), &path)
    expect(response).to redirect_to(instance_exec(&not_found_path))
    expect(flash[:alert]).to eq(I18n.t(not_found))
  end

  it "does not serve an unpublished record on this domain" do
    get instance_exec(record_on(domain, published: false), &path)
    expect(response).to redirect_to(instance_exec(&not_found_path))
    expect(flash[:alert]).to eq(I18n.t(not_found))
  end
end
