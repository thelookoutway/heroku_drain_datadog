module HerokuDrainDatadog
  class LogEntry
    attr_reader :timestamp
    attr_reader :service
    attr_reader :data

    def initialize(timestamp:, service:, data:)
      @timestamp = timestamp
      @service = service
      @data = data
    end
  end
end
