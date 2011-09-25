### Application structure

An application is just a Ruby script:

    #!/usr/bin/env ruby

    require 'posts'
    require 'users'

    Raptor.new([Posts, Users]).attack!

Running this script will start a server [TODO], just like Sinatra would. There's no autoloader and no discovery of your code: you explicitly require your resources and give them to Raptor.

### Resources

An application is composed of resources. A resource includes database records, presenters, views, and routes, or any subset of those. Not all resources can be accessed directly through HTTP, and not all resources map directly onto database records.

Resources are composed of plain old Ruby objects. Sometimes, Raptor uses conventions to instantiate or interact with them [TODO], but the objects themselves are simple. There are no base classes to inherit from. (The one exception to this is routing, because it's pure configuration.)

### Routes

Routes are the core of Raptor, and are much more powerful than in most web frameworks. They can delegate requests to domain objects [TODO], enforce request constraints (like "user must be an admin") [TODO], redirect based on exceptions [TODO], and render views. They also automatically apply presenters before rendering. For example:

    class Posts
      Routes = Raptor.routes(self) do
        show
        edit
        update :require => :admin
      end

      class OnePresenter
        ...
      end

      class Record
        ...
      end
    end

`Posts` is the resource. It has routes, a presenter, and records in a database (nevermind their implementation for now). Let's take the routes in order.

`show` has no arguments, so it inherits the default show behavior:

1. Match GET "/posts/:id"
1. Extract the ID
1. Call `Posts::Record.find_by_id` with the ID, returning `record`
1. Instantiate a `Posts::OnePresenter.new(record)`
1. Render `views/posts/show.html.erb` with the presenter as its context

Each of these is customizable, and each of the seven standard actions has a slightly different set of defaults, mostly in steps 2 and 3.

`edit` is similar, except that it doesn't extract an ID from the URL or call a model method; it just constructs a presenter and renders a view.

`update` is more interesting. It has an admin requirement, so the request lifecycle is:

1. Match PUT "/posts/:id"
1. Extract the ID
1. Call `Posts::Record.find_by_id` with the ID, returning `record`
1. Enforce the :admin requirement. If the user isn't an admin, it return HTTP 403 Forbidden and end this process.
1. Call `record.update_attributes`, passing in the incoming params
1. Redirect to `/posts/:id` with the ID filled in

### Requirements / constraints

[TODO choose name of these things]

Requirements are always enforced immediately after record retrieval.

### Specifying the authentication mechanism

### Raptor request process

- Step through all routes, choosing the first that matches.
- Delegate to the domain object, inferring arguments as needed.
  - If an exception is raised, route it and end this process
- Instantiate the presenter with the domain object
- Pass the presenter to the template

### Implementation

It's as you'd expect:

    class App
      def call(env)
        route = routes.find { |r| r.matches?(env) }
        route.call(env)
      end
    end

    class Route
      def call(env)
        begin
          domain_object = route.build_domain_object
        rescue Exception => e
          presenter = route.handle_exception(exception)
        end
        presenter = route.build_presenter(domain_object)
        render(presenter)
      end
    end

### Argument inference

Domain objects, presenters, and requirements can infer certain arguments. For example, consider this presenter:

    class PresentsUsers
      def initialize(params, user)
        @params = params
        @user = user
      end

      ...
    end

Because the Presenter's initializer takes an argument named `params`, the router will automatically be populated with the params hash when the router instantiates it.

From the application's point of view, this achieves roughly the same result as a Rails controller: you can access the params, or plenty of other request-related state, if you need to. But has some additional benefits:

* More than just request-state can be inferred. If your presenter method takes an argument named `post`, and there's a resource named Post, and there's a param value at `params[:post][:id]`, then Raptor will automatically retrieve that post for you. By simply naming your argument `post`, you're telling the Raptor router that you want the relevant post record injected.

* Testability: the presenter (or domain object or requirement) is still just a regular object with a regular initializer. When you test it, you can just new it up with appropriate arguments. There are no controller classes full of implicit interactions.

### Design Notes / Constraints

- All scripts will comform to Unix argument conventions
- All scripts will die immediately on ^C
- All scripts, and framework loads, will take less than 100 ms
- Autoreload will happen by killing and restarting, not in-place
- Releases will follow semantic versioning

### Sanity Notes

- Mutating a record in a presenter is an error
- A resource may not be named "params"

### Testing

- Running request tests generates transcripts of the requests as text files. Reviewing these on commit can reveal unintended changes.
- Add request metatests that duplicate requests that should be idempotent (everything except POSTs) and verify that they actually are. (Good idea?)

### Possible database layer primitives

https://github.com/nateware/redis-objects

