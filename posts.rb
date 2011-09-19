module Posts
  Routes = Raptor.routes do
    index
    new
    create
    show "Posts::Record#find_by_id"
    edit
    update "post#update", :require => :user_owns_post, NotLoggedIn => redirect('/')
    update :render => :forbidden
    destroy
  end

  class PresentsOne < Shorty
    composed_of :current_user
    present :date { post.date.as_delta }
    present :highlighted? { post.user.is_admin? }
    present :mine? { post.user == current_user }
  end

  class PresentsMany
  end

  class Record
  end
end

