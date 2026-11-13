module Learners
  class Mailer < Devise::Mailer
    include LearnerMailTenancy

    protected

    def devise_mail(record, action, opts = {}, &block)
      use_domain(Domain.find_by(id: opts.delete(:domain_id)) || record.domain || raise(ArgumentError, "no site to send learner mail from"))
      super(record, action, opts.merge(from: @identity.from, reply_to: nil), &block)
    end
  end
end
