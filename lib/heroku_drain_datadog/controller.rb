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

      tags = default_tags + derive_tags(log_entry.data, service)
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

    def derive_tags(data, service)
      service.tags.reduce([]) do |tags, tag|
        raw_value = data[tag.heroku_name]
        unless raw_value
          @logger.debug("[#{self.class}#derive_tags] skipping, missing value")
          return tags
        end

        typed_value = coerce_value(raw_value, tag.type)
        unless typed_value
          @logger.debug("[#{self.class}#derive_tags] skipping, failed to coerce type")
          return tags
        end

        tags << "#{tag.datadog_name}:#{typed_value}"
        tags
      end
    end

    def coerce_value(value, type)
      case type
      when :float
        value.to_f
      when :integer
        value.to_i
      when :string
        value.to_s.tr("\"", "")
      when :Source2DynoType
        Source2DynoType.coerce(value)
      end
    end

    class Source2DynoType
      def self.coerce(value)
        value.split(".").first
      end
    end
    private_constant :Source2DynoType
  end
end
