class Avo::Actions::RevokeCertificate < Avo::BaseAction
  self.name = "Revoke certificate"
  self.message = "The certificate number stays verifiable and shows as revoked."

  def handle(records:, **)
    records.each { |certificate| certificate.update!(revoked_at: certificate.revoked_at || Time.current) }
    succeed "Certificate revoked"
  end
end
