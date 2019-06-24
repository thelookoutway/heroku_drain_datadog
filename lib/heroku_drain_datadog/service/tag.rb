module HerokuDrainDatadog
  class Service
    class Tag
      attr_reader :heroku_name, :datadog_name, :type

      def initialize(heroku_name:, datadog_name:, type:)
        @heroku_name = heroku_name
        @datadog_name = datadog_name
        @type = type
      end
    end
  end
end
