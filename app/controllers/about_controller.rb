class AboutController < ApplicationController
  before_action :setup_breadcrumbs, only: [ :index ]
  def index
    expires_in 1.hour, public: true
    set_meta_tags(
      title: "عن موقع العلم",
      description: "تعرف على موقع العلم ومكتبته الشرعية التي تجمع الكتب والدروس والمحاضرات والسلاسل العلمية والفتاوى والمقالات في مكان واحد.",
      canonical: canonical_url_for,
      og: {
        title: "عن موقع العلم",
        description: "تعرف على موقع العلم ومكتبته الشرعية التي تجمع الكتب والدروس والمحاضرات والسلاسل العلمية والفتاوى والمقالات في مكان واحد.",
        type: "website",
        url: canonical_url_for
      }
    )
  end

  private

  def setup_breadcrumbs
    breadcrumb_for(t("breadcrumbs.about"), about_path)
  end
end
