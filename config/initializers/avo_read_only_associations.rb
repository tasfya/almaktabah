# Community Avo checks attach/detach only through an authorization client,
# which this app does not configure, so a hand-made request could attach or
# detach (and, with dependent: :destroy, delete) records of a read-only
# resource through a parent's panel. Refuse those for read-only resources.
Rails.application.config.to_prepare do
  Avo::AssociationsController.class_eval do
    def refuse_read_only_association_writes
      raise Avo::NotAuthorizedError if @related_authorization.is_a?(Avo::ReadOnlyAuthorization)
    end
    private :refuse_read_only_association_writes

    skip_before_action :refuse_read_only_association_writes, raise: false
    before_action :refuse_read_only_association_writes, only: %i[new create destroy]
  end
end
