$LOAD_PATH << "lib" << "spec"
require 'raptor'
require 'fake_resources'

def request(path)
  Rack::Request.new('PATH_INFO' => path, 'rack.input' => {})
end

