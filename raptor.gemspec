Gem::Specification.new do |s|
  s.name = "raptor"
  s.version = "0.0.1"

  s.authors = ["Gary Bernhardt, Tom Crayford"]
  s.email = ["email@here.com"]
  s.files = Dir.glob("lib/**/*") + ["README.md"]
  s.homepage = %q{https://github.com/garybernhardt/raptor}
  s.require_paths = ["lib"]
  s.summary = "Raptor"
  s.description = "Raptor"

  s.add_development_dependency "rspec"
  s.add_dependency "rack"

  s.require_path = "lib"
  s.required_rubygems_version = ">= 1.3.6"
end
