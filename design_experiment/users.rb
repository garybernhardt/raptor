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

module Models
  class User
    extend Raptor::Model
    delegate [:email, :posts] => :@record

    def anonymous?; false; end
  end

  class AnonymousUser
    def anonymous?; true; end
  end
end

