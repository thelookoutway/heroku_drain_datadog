require "rack/request"
require "rack/utils"

module Rack
  class RequestCounter
    def initialize(app, statsd:)
      @app = app
      @statsd = statsd
    end

    def call(env)
      begin
        status, headers, body = @app.call(env)
        count(status, env)
        [status, headers, body]
      rescue => error
        count(Rack::Utils.status_code(:internal_server_error), env)
        raise error
      end
    end

    private

    def count(status, env)
      request = Rack::Request.new(env)
      tags = [
        "status:#{status}",
        "host:#{request.host}",
        "path:#{request.path}",
      ]
      @statsd.increment("heroku.drain.request", tags: tags)
    end
  end
end
