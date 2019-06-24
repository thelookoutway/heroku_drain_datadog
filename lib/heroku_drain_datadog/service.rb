require "heroku_drain_datadog/service/metric"
require "heroku_drain_datadog/service/tag"

module HerokuDrainDatadog
  class Service
    attr_reader :metrics, :tags

    def initialize(metrics:, tags:)
      @metrics = metrics
      @tags = tags
    end
  end
end
