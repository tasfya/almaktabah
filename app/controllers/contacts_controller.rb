class ContactsController < ApplicationController
  before_action :setup_breadcrumbs, only: [ :new, :create ]

  def new
    @contact = Contact.new
  end

  def create
    @contact = Contact.for_domain(@domain).new(contact_params)
    if @contact.save
      redirect_to contact_path, notice: t("messages.contact_success")
    else
      render :new
    end
  end

  private

  def contact_params
    params.require(:contact).permit(:name, :email, :subject, :message)
  end

  def setup_breadcrumbs
      breadcrumb_for(t("breadcrumbs.contact"), contact_path)
  end
end
