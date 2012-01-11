Routes = Raptor.routes do
  path "posts" do
    # We could also scope all route targets inside Interactors, allowing this
    # to say :to => "CreatePost.create".
    create :to => "Interactors::CreatePost.create",
      :ValidationFailure => render(:new)
  end
end

