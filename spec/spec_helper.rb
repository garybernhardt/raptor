$LOAD_PATH << "lib" << "spec"
require 'raptor'
require 'fake_resources'

def request(method, path, body="")
  Rack::Request.new('REQUEST_METHOD' => method,
                    'PATH_INFO' => path,
                    'rack.input' => body)
end

