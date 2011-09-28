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

