module LearnerArea
  class DashboardController < ApplicationController
    before_action :authenticate_learner!
    before_action :no_store

    def show
      set_meta_tags(title: t("programs.dashboard.title"), noindex: true)
    end
  end
end
