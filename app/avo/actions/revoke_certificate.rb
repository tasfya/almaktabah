class Avo::Actions::RevokeCertificate < Avo::BaseAction
  self.name = "إلغاء الشهادة"
  self.message = "يبقى رقم الشهادة قابلًا للتحقق ويظهر أنها ملغاة."

  def handle(records:, **)
    records.each { |certificate| certificate.update!(revoked_at: certificate.revoked_at || Time.current) }
    succeed "أُلغيت الشهادة"
  end
end
