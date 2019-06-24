require "yaml"
require "heroku_drain_datadog/service"

module HerokuDrainDatadog
  class Configuration
    def self.default
      load(File.expand_path("../../../config/default.yml", __FILE__))
    end

    def self.load(path)
      new(YAML.load_file(path))
    end

    def initialize(options)
      @services = options.reduce({}) do |services, (service_name, service_options)|
        service = Service.new(
          metrics: extract_metrics(service_options),
          tags: extract_tags(service_options)
        )
        services.merge(service_name.to_sym => service)
      end
    end

    def [](key)
      @services[key]
    end

    private

    def extract_metrics(options)
      options.fetch("metrics", []).reduce([]) do |metrics, metric_options|
        if metric_options["enabled"] == true
          metrics << Service::Metric.new(
            heroku_name: metric_options.fetch("heroku_name"),
            datadog_name: metric_options.fetch("datadog_name"),
            type: metric_options.fetch("type").to_sym,
            metric: metric_options.fetch("metric").to_sym,
          )
        end
        metrics
      end
    end

    def extract_tags(options)
      options.fetch("tags", []).map do |tag_options|
        Service::Tag.new(
          heroku_name: tag_options.fetch("heroku_name"),
          datadog_name: tag_options.fetch("datadog_name"),
        )
      end
    end
  end
end
