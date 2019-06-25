require "roda"
require "heroku_drain_datadog/http/log_controller"
require "rack/request_counter"

module HerokuDrainDatadog
  module HTTP
    class Router
      def initialize(config:, logger:, statsd:)
        @app = Class.new(Roda) do
          plugin :drop_body

          # Track incoming requests, even if there's an exception.
          use Rack::RequestCounter, statsd: statsd

          # Protect endpoint with a password.
          use Rack::Auth::Basic do |_, password|
            Rack::Utils.secure_compare(ENV.fetch("DRAIN_PASSWORD"), password)
          end

          route do |r|
            # POST /logs
            r.post "logs" do
              controller = LogController.new(config: config, logger: logger, statsd: statsd)
              response.status, body = controller.call(request)
              body
            end
          end
        end
      end

      def app
        @app.app
      end
    end
  end
end
