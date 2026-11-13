module Learners
  class ConfirmationsController < Devise::ConfirmationsController
    include LearnerSite
  end
end
