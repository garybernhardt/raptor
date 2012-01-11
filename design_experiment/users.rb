module Injectables
  def current_user(session)
    begin
      id = session.fetch(:user_id)
    rescue KeyError
      AnonymousUser.new
    else
      Models::User.find(id)
    end
  end
end

