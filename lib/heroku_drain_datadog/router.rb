require "roda"
require "heroku_drain_datadog/controller"
require "rack/request_counter"

module HerokuDrainDatadog
  class Router
    BLANK = ""

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
            default_tags = derive_default_tags(r.env["HTTP_LOGPLEX_DRAIN_TOKEN"])
            controller = Controller.new(config: config, logger: logger, statsd: statsd)
            controller.call(request.body.read, default_tags: default_tags)
            response.status = 204
            BLANK
          end
        end

        private

        def derive_default_tags(drain_token)
          return [] unless drain_token

          tags = ["drain:#{drain_token}"]
          app_name = ENV["DRAIN_#{drain_token}"]
          if app_name
            tags << "app:#{app_name}"
          end
          tags
        end
      end
    end

    def app
      @app.app
    end
  end
end
