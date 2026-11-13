# Public verification page for a certificate number, printable on A4. Served
# only on the site the certificate was issued on. Never cached: a revoked
# certificate must stop reading as valid at once.
class CertificatesController < ApplicationController
  include TransientBreadcrumbs

  before_action :no_store

  def show
    @certificate = Certificate.includes(enrollment: { cohort: :program }).find_by(number: params[:id], domain_id: @domain.id)
    return render_record_not_found(t("programs.certificate.not_found"), root_path) unless @certificate

    reset_breadcrumbs
    @cohort = @certificate.enrollment&.cohort
    set_meta_tags(title: t("programs.certificate.page_title", number: @certificate.number), noindex: true, nofollow: true)
  end
end
