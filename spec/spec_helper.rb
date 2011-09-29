$LOAD_PATH << "lib" << "spec"
require 'raptor'
require 'fake_resources'

def env(method, path, body="")
  {'REQUEST_METHOD' => method,
   'PATH_INFO' => path,
   'rack.input' => body}
end

def request(method, path, body="")
  Rack::Request.new(env(method, path, body))
end

# The first instantiation of these is very slow for some reason. Do it here so
# it doesn't pollute test runtimes.
Rack::Request.new({})
Rack::Response.new

