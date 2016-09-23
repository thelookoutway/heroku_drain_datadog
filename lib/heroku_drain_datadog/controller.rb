require "heroku_drain_datadog/parser"

module HerokuDrainDatadog
  class Controller
    def initialize(config:, logger:, statsd:)
      @config = config
      @logger = logger
      @statsd = statsd
      @parser = Parser.new
    end

    def call(buffer, default_tags: [])
      @logger.debug("[#{self.class}#call] #{buffer}")
      log_entries = @parser.call(buffer)
      log_entries.each do |log_entry|
        send_stats(log_entry, default_tags)
      end
    end

    private

    def send_stats(log_entry, default_tags)
      service = @config[log_entry.service]
      unless service
        return
      end

      tags = default_tags + derive_tags(log_entry.data, service.tags)
      service.metrics.each do |metric|
        raw_value = log_entry.data[metric.heroku_name]
        unless raw_value
          @logger.debug("[#{self.class}#send_stats] skipping, missing value")
          next
        end
        typed_value = coerce_value(raw_value, metric.type)
        unless typed_value
          @logger.debug("[#{self.class}#send_stats] skipping, failed to coerce type")
          next
        end

        @statsd.send(
          metric.metric,
          metric.datadog_name,
          typed_value,
          tags: tags,
        )
      end
    end

    def derive_tags(data, keys)
      keys.reduce([]) do |tags, key|
        value = data[key]
        tags << "#{key}:#{value.tr("\"", "")}" if value
        tags
      end
    end

    def coerce_value(value, type)
      case type
      when :float
        value.to_f
      when :integer
        value.to_i
      end
    end
  end
end
