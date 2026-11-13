module Learners
  class SessionsController < Devise::SessionsController
    include LearnerSite
  end
end
