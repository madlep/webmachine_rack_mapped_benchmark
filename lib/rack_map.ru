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

map '/' do
  run MyWebmachineApp.adapter
  map '/webmachine' do
    run MyWebmachineApp.adapter
  end
end
