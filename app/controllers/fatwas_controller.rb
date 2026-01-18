# frozen_string_literal: true

class FatwasController < ApplicationController
  include TypesenseListable
  before_action :set_fatwa, only: [ :show ]
  before_action :setup_fatwas_breadcrumbs

  def index
    typesense_collection_search("fatwa")
  end

  def show
    description = @fatwa.question.present? ? @fatwa.question.to_plain_text.truncate(155) : ""
    set_meta_tags(
      title: @fatwa.title,
      description: description,
      canonical: canonical_url,
      og: {
        title: @fatwa.title,
        description: description,
        type: "article",
        url: canonical_url
      }
    )
  end

  private

  def set_fatwa
    @fatwa = Fatwa.friendly
                  .for_domain_id(@domain.id)
                  .published
                  .find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to fatwas_path, alert: t("messages.fatwa_not_found")
  end

  def setup_fatwas_breadcrumbs
    case action_name
    when "index"
      breadcrumb_for(t("breadcrumbs.fatwas"), fatwas_path)
    when "show"
      breadcrumb_for(t("breadcrumbs.fatwas"), fatwas_path)
      breadcrumb_for(@fatwa.title, fatwa_path(@fatwa))
    end
  end
end
