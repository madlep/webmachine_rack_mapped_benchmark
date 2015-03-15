require 'webmachine'
require 'webmachine/adapters/rack'
require 'json'

MyWebmachineApp = Webmachine::Application.new do |app|
  class TestResource < Webmachine::Resource
    def allowed_methods
      ["POST"]
    end

    def content_types_accepted
      [["application/json", :from_json]]
    end

    def content_types_provided
      [["application/json", :to_json]]
    end

    def post_is_create?
      true
    end

    def create_path
      "created_path_here/#{request.path_info[:test_id]}"
    end

    def from_json
      response.body = %{ {"foo": "bar"} }
    end

    def to_json
      %{ {"fuz": "boz"} }
    end
  end

  app.routes do
    add ["test", :test_id], TestResource
    add ["webmachine", "test", :test_id], TestResource
  end

  app.configure do |config|
    config.adapter = if defined?(Rack::RackMapped)
                       :RackMapped
                       else
                         :Rack
                       end
  end
end

app = Rack::Builder.new do
  map '/' do
    map '/webmachine' do
      run MyWebmachineApp.adapter
    end
  end
end.to_app

require 'benchmark'
n = 10000
rack_env = {"GATEWAY_INTERFACE"=>"CGI/1.1",
            "PATH_INFO"=> defined?(Rack::RackMapped) ? "/test/123" : "/webmachine/test/123",
            "QUERY_STRING"=>"",
            "REMOTE_ADDR"=>"127.0.0.1",
            "REMOTE_HOST"=>"localhost",
            "REQUEST_METHOD"=>"POST",
            "REQUEST_URI"=>"http://localhost:9292/webmachine/test/123",
            "SCRIPT_NAME"=> defined?(Rack::RackMapped) ? "/webmachine" : "",
            "SERVER_NAME"=>"localhost",
            "SERVER_PORT"=>"9292",
            "SERVER_PROTOCOL"=>"HTTP/1.1",
            "SERVER_SOFTWARE"=>"WEBrick/1.3.1 (Ruby/2.2.1/2015-02-26)",
            "HTTP_HOST"=>"localhost:9292",
            "HTTP_USER_AGENT"=>"HTTPie/0.8.0",
            "HTTP_ACCEPT_ENCODING"=>"gzip, deflate, compress",
            "HTTP_ACCEPT"=>"*/*",
            "HTTP_CONTENT_TYPE"=>"application/json",
            "rack.version"=>[1, 3],
            "rack.input"=>%{{"foo": "bar"}},
            "rack.errors"=>STDERR,
            "rack.multithread"=>true,
            "rack.multiprocess"=>false,
            "rack.run_once"=>false,
            "rack.url_scheme"=>"http",
            "rack.hijack?"=>false,
            "HTTP_VERSION"=>"HTTP/1.1",
            "REQUEST_PATH"=>"/hello"}

Benchmark.bmbm do |x|
  x.report { n.times { app.call(rack_env) } }
end

