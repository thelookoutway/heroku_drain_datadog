module HerokuDrainDatadog
  class Service
    class Tag
      attr_reader :heroku_name, :datadog_name

      def initialize(heroku_name:, datadog_name:)
        @heroku_name = heroku_name
        @datadog_name = datadog_name
      end
    end
  end
end
