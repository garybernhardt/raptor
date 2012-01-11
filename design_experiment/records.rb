module Records
  class User < SomeORM::Record
    value :email
    list :posts => "Post"
  end

  class Post < SomeORM::Record
    value :title
    value :body
    reference :author => "User"
  end
end

