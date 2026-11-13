module Learners
  class PasswordsController < Devise::PasswordsController
    include LearnerSite
  end
end
