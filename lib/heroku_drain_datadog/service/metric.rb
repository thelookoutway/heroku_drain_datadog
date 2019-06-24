module HerokuDrainDatadog
  class Service
    class Metric
      attr_reader :heroku_name, :datadog_name, :name, :type, :metric

      def initialize(heroku_name:, datadog_name:, type:, metric:)
        @heroku_name = heroku_name
        @datadog_name = datadog_name
        @name = name
        @type = type
        @metric = metric
      end

      def coerce(value:)
        case type
        when :float
          value.to_f
        when :integer
          value.to_i
        end
      end
    end
  end
end
