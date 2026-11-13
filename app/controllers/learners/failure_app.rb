module Learners
  # A guest reaching a learner page is the normal first step, not an error:
  # the sign-in page shows the "sign in first" message as information.
  class FailureApp < Devise::FailureApp
    def redirect
      # Learner pages are no-store; their sign-in redirect is built here,
      # outside the controller, so it needs the header too.
      headers["Cache-Control"] = "no-store" if scope == :learner
      return super unless scope == :learner && (warden_message || :unauthenticated) == :unauthenticated && is_flashing_format?

      store_location!
      flash[:info] = i18n_message
      redirect_to redirect_url
    end
  end
end
