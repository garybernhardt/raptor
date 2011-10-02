# Raptor

https://github.com/garybernhardt/raptor

## DESCRIPTION

R-A-P-T-O-R, taken in order of importance:

**A: Application**: The entire Raptor application is an object that conforms to the Rack interface. You can pass it around if you like. Even mount it as part of a larger Rack app if you like.

**R: Routes**: More powerful than you're used to. They route both in (via URL, verb, etc.) and out (by mapping raised exceptions to redirects and renders).

**O: [plain old] Objects**: No controllers. Put your logic in a plain old Ruby object. Raptor will pass it whatever it needs&mdash;database records, form parameters, the request URL, or nothing, if it needs nothing.

**R: [database] Records**: You decide what this means. Your records just need to comform to Raptor's expected interface.

**P: Presenter**: All template rendering goes through a presenter. At the end of a request, the presenter is automatically instantiated and used to render the template.

**T: Template**: Same as it ever was.

There are some other components that act as plumbing in your app:

**Inferables**: Raptor will infer which arguments your objects need based on their names. Inferables are providers for those arguments. For example, you might write an inferable that provides current\_user for any method that needs it.

**Requirements**: These are higher-level routing constraints based on more than just the URL or HTTP method. For example, you could create a route that's only triggered for paying users.

Controllers are conspicuously absent from all of this. All of the controller's responsibilities are provided by these other mechanisms: selective code execution based on the objects in play (requirements), translation of exceptional conditions into redirects and renders (routes), and construction of a template rendering environment (presenters).

## Application structure

An application is just a Ruby script:

    #!/usr/bin/env ruby

    require 'posts'
    require 'users'

    App = Raptor.new([Posts, Users])

`App` is now a Rack app, so you can create a standard config.ru:

    require './app'
    run App

and run the app with `rackup`:

    $ rackup

There's no autoloader and no discovery of your code: you explicitly require your resources, give them to Raptor, and get back a Rack app.

## Resources

An application is composed of resources. A resource includes database records, presenters, views, and routes, or any subset of those. Not all resources can be accessed directly through HTTP, and not all resources map directly onto database records.

Resources are composed of plain old Ruby objects. Sometimes, Raptor uses conventions to instantiate or interact with them, but the objects themselves are simple. There are no base classes to inherit from. (The one exception to this is routing, because it's pure configuration.)

## Routes

Routes are the core of Raptor, and are much more powerful than in most web frameworks. They can delegate requests to domain objects, enforce request constraints (like "user must be an admin") [TODO], redirect based on exceptions [TODO], and render views. They also automatically apply presenters before rendering. For example, here's a `Posts` resource:

    module Posts
      Routes = Raptor.routes(self) do
        show
        edit
        update :require => :admin
      end

      class PresentsOne
        ...
      end

      class Record
        ...
      end
    end

`Posts` is the resource. It has routes, a presenter, and records in a database (never mind their implementation for now). Let's take the routes in order.

`show` has no arguments, so it inherits the default show behavior:

1. Match GET "/posts/:id"
1. Extract the ID
1. Call `Posts::Record.find_by_id` with the ID, returning `record`
1. Instantiate a `Posts::PresentsOne.new(record)`
1. Render `views/posts/show.html.erb` with the presenter as its context

Each of these is customizable, and each of the seven standard actions has a slightly different set of defaults, mostly in steps 2 and 3.

`edit` is similar, except that it doesn't extract an ID from the URL or call a model method; it just constructs a presenter and renders a view.

`update` is more interesting. It has an admin requirement, so the request lifecycle is:

1. Match PUT "/posts/:id"
1. Extract the ID
1. Call `Posts::Record.find_by_id` with the ID, returning `record`
1. Enforce the `:admin` requirement. If the user isn't an admin, return HTTP 403 Forbidden and end this process.
1. Call `record.update_attributes`, passing in the incoming params
1. Redirect to `/posts/:id` with the ID filled in

## Requirements / constraints

[TODO choose name of these things]

Requirements are always enforced immediately after record retrieval.

## Complex behavior and the injector

If your `show` route needs to do more than simply retrieve a record, that's not a problem. You can route to any method:

    module Profiles
      Routes = Raptor.routes(self) do
        show "Profile.from_user"
      end

      class Profile
        def self.from_user(user)
          ...
        end
      end
    end

The `show` route here delegates to the `Profile.from_user` method, which presumably takes a `user` argument. Raptor knows that it needs to call this method, and it knows that the method takes a `user`. It looks through its list of injectables [TODO: name?] for one called "user". There is one by default, `Raptor::Injectables::CurrentUser`, which returns the current logged-in user. Raptor calls it to get the current user, then passes it to `Profile.from_user`. From there, it goes through the normal request process: it builds a Profiles::PresentsOne from the profile and renders `views/profiles/show.html.erb` with it.

Raptor will infer arguments to all kinds of things: domain objects, as shown here, but also presenters, records, and requirements. This is how form parameters are handled, for example. If your route delegates to `PostCreator.create(params)`, Raptor will automatically inject the actual request params as an argument. You can do the stuff you'd do in a Rails controller without hard coupling yourself to an ActionController::Base class. The reduced coupling makes testing super easy and allows reuse (anyone who needs to create a post can use PostCreator!)

## Specifying the authentication mechanism

## General raptor request process

The seven routes' exact behavior differs, but shares this skeleton:

- Step through all routes, choosing the first that matches.
- Delegate to the domain object, which may be a record, inferring arguments as needed.
  - If an exception is raised, route it and end this process
- Instantiate the presenter with the domain object
- Pass the presenter to the template

## Design Notes / Constraints

- All scripts will comform to Unix argument conventions
- All scripts will die immediately on ^C
- All scripts, and framework loads, will take less than 100 ms
- Autoreload will happen by killing and restarting, not in-place
- Releases will follow semantic versioning

## Sanity Notes

- Mutating a record in a presenter is an error
- No two injectables may register the same name

## Testing

- Running request tests generates transcripts of the requests as text files. Reviewing these on commit can reveal unintended changes.
- Add request metatests that duplicate requests that should be idempotent (everything except POSTs) and verify that they actually are. (Good idea?)

## Possible database layer primitives

https://github.com/nateware/redis-objects

