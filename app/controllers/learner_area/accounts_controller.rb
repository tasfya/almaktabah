module LearnerArea
  class AccountsController < BaseController
    before_action :set_page

    def show
      @learner = current_learner
    end

    def update
      @learner = current_learner
      if @learner.update(params.expect(learner: [ :full_name, :gender ]))
        redirect_to learner_account_path, notice: t("programs.account.updated")
      else
        render :show, status: :unprocessable_content
      end
    end

    # Enrollments, ticks and attempts go with the account; certificates stay
    # as revoked (see Enrollment) so a printed number still resolves.
    def destroy
      @learner = current_learner
      unless @learner.valid_password?(params[:current_password].to_s)
        flash.now[:alert] = t("programs.account.wrong_password")
        return render :show, status: :unprocessable_content
      end

      @learner.destroy!
      sign_out(:learner)
      redirect_to new_learner_session_path, notice: t("programs.account.deleted")
    end

    private

    def set_page
      set_meta_tags(title: t("programs.account.title"), noindex: true)
      breadcrumb_for(t("programs.account.title"), learner_account_path)
      @enrollments = domain_enrollments.includes(cohort: :program).order(enrolled_at: :desc)
    end
  end
end
