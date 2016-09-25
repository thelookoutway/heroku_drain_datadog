require "time"
require "heroku_drain_datadog/log_entry"

module HerokuDrainDatadog
  class Parser
    ASSIGN_CHAR = "="
    DYNO_SERVICE = /\.\d+\Z/
    HEROKU_SERVICE = "heroku"
    NEW_LINE_CHAR = "\n"
    POSTGRES_SERVICE = "heroku-postgres"
    REDIS_SERVICE = "heroku-redis"
    ROUTER_SERVICE = "router"
    SPACE_CHAR = " "

    def call(buffer)
      buffer.split(NEW_LINE_CHAR).reduce([]) do |log_entries, line|
        log_entry = parse_log_entry(line)
        log_entries << log_entry if log_entry
        log_entries
      end
    end

    private

    def parse_log_entry(line)
      tokens = line.split(SPACE_CHAR)
      if tokens.size < 7
        return
      end

      service = extract_service(tokens[4..5])
      unless service
        return
      end

      timestamp = extract_timestamp(tokens[2])
      unless timestamp
        return
      end

      data = extract_data(tokens[6..-1])
      unless data
        return
      end

      LogEntry.new(timestamp: timestamp, service: service, data: data)
    end

    def extract_timestamp(token)
      Time.parse(token)
    end

    def extract_service(tokens)
      case
      when tokens[0] == HEROKU_SERVICE && tokens[1] == ROUTER_SERVICE
        :router
      when tokens[0] == HEROKU_SERVICE && tokens[1] =~ DYNO_SERVICE
        :dyno
      when tokens[1] == REDIS_SERVICE
        :redis
      when tokens[1] == POSTGRES_SERVICE
        :postgres
      end
    end

    def extract_data(tokens)
      tokens.reduce({}) do |data, token|
        key, value = token.split(ASSIGN_CHAR)
        if key && value
          data.merge(key => value)
        else
          data
        end
      end
    end
  end
end
