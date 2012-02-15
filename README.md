# Raptor

https://github.com/garybernhardt/raptor

## DESCRIPTION

Raptor is an experimental web framework that encourages simple, decoupled objects. There are no base classes and as little "DSL" as possible. Raptor is not MVC; at least, not in the way that frameworks like Rails are. An example would be handy right about now:

```ruby
module MyApp
  Routes = Raptor.routes do
    path "article"
      show
      index
      update :require => :admin, :redirect => :index
    end
  end

  module Records
    class Article < YourFavoriteORM::Record
      # Do as you please
    end
  end

  module Requirements
    class Admin
      def match?(params)
        Records::Article.find_by_id(params[:user_id]).admin?
      end
    end
  end

  module Presenters
    class Article
      def initialize(subject); @subject = subject; end
      def slug; @subject.title.to_slug; end
    end
  end
end
```

The first thing you notice: that's a lot of modules! Yes it is. You can break them into files in whatever way you want, but Raptor does expect this layout once everything is loaded.

The second thing you notice: there's no controller! Yes; this is because controllers are the devil. Instead, Raptor has an extremely powerful router:

## Routes

Routes can:

- delegate requests to objects you create.
- enforce constraints (like "user must be an admin" in the example above).
- redirect on success, or on certain exceptions, or both.
- render views.
- apply presenters before rendering.

The `update` route in the above example uses the default update behavior we know and love: the same stuff you've written in a hundred Rails controller actions. This behavior is the default in Raptor, but is completely overrideable. Here we've overrided it to redirect to index instead of show, and to only work for admins. The request lifecycle is:

1. Match PUT "/article/:id".
1. Enforce the `:admin` requirement, defined by us in `MyApp::Requirements::Admin`. If the user isn't an admin, stop. The route doesn't match, even though the verb and path do.
1. Call `MyApp::Records::Article.find_and_update`. It takes `id` and `params`. Raptor's dependency injector notices this, extracts the ID from the URL, as well as the params from the request, and passes them in.
1. Redirect to `/article`, the index path. By default it would've gone to the show path, but we overrode it.

In addition, if `find_and_update` raised `Raptor::ValidationError`, it would've redirected to `:edit`. If a template had been rendered, it would've gone through `MyApp::Presenters::Article`. The full expansion of the update route is:

    route :update, "PUT", "article/:id",
      :to => "MyApp::Records::Article.find_and_update",
      :redirect => :show, ValidationError => :edit`

All of the standard Raptor routes are syntactic sugar for these longer forms.

## Application structure

By default, the router delegates to records. Records are not to contain application logic; delegation directly to records is only acceptable for very simple operations. For anything complex, it's your job to create relevant objects and point the router at them. Raptor provides you niceties related to the web: routing, presentation, template rendering, etc., but the core of your application&mdash;the logic&mdash;should have its own design that Raptor can't know ahead of time.

Raptor currently has no database layer. The records themselves are your job. As long as they have methods that match Raptor's interface, you'll be fine.

## Rack apps and serving

An application is just a Ruby script:

```ruby
#!/usr/bin/env ruby
require 'article'
App = Raptor::App.new(MyApp)
```

`App` is now a Rack app, so you can create a standard config.ru:

```ruby
require './app'
run App
```

and run the app with `rackup`:

```
$ rackup
```

There's no autoloader and no discovery of your code: you explicitly require your source, give your app module to Raptor, and get a Rack app back.

## Complex behavior and the injector

Any method that Raptor calls will be injected: subjects, presenters, requirements, even other injectables. Injection is purely name-based: if you have a method named `request`, it will get the Rack request as an argument. It's your job not to ask for HTTP data in deep layers of your application, like records (unless you really want to, in which case you can, but you should at least feel guilty about it).

Injection is how form parameters are handled, for example. If your route delegates to `PostCreator.create(params)`, Raptor will automatically inject the request params as an argument. You can do the stuff you'd do in a Rails controller without hard coupling yourself to an ActionController::Base class. The reduced coupling makes testing easy and allows reuse (anyone who needs to create a post can use PostCreator!)

To define your own injectables , just define a class:

```ruby
class MyApp::Injectables::Fruit
  def sources(injector)
    {:watermelon => lambda { "tasty" } }
  end
end
```

Now, if Raptor calls one of your methods that takes a `watermelon` argument, it will be passed "tasty".

## LICENSE

Released under the MIT license:

* http://www.opensource.org/licenses/MIT

