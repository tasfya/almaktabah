# Avo runs without an authorization client, so every resource can be created,
# edited and destroyed. Resources that only display records hand this to Avo to
# refuse those requests server-side and hide their buttons; actions still run.
class Avo::ReadOnlyAuthorization < Avo::Services::AuthorizationService
  WRITES = %i[new create edit update destroy attach detach].freeze

  def authorize_action(action, raise_exception: true, **)
    return true unless WRITES.include?(action.to_sym)
    raise Avo::NotAuthorizedError if raise_exception

    false
  end
end
