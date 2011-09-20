%{
  /
    Gemfile
    raptor
    config.ru
    router/
      requirements.rb
      routes.rb
    app.rb
    presenters/
      posts.rb
    template/
      posts/
        show.html.erb
        list.html.erb
    objects/
      posts.rb
    records/
      posts.rb
}
module Requirements
  def user_owns_post?(post, user)
    post.user == user
  end
end

resource :posts do
  item.get :show
  item.put :update, :require => :user_owns_post
  item.put :render => :forbidden
  collection.get :list
end

class DAS::Models::Posts
  def self.show(params)
    Post::Query.by_id(params[:post][:id])
  end

  def self.list
    Post::Query.all
  end

  def self.update(params)
    Post::Query.
  end
end

