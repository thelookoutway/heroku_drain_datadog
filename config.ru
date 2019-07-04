$LOAD_PATH.unshift File.expand_path("../lib", __FILE__)
require "heroku_drain_datadog"
require "logger"
require "datadog/statsd"

logger = Logger.new(STDOUT).tap { |l| l.level = ENV.fetch("LOG_LEVEL", Logger::Severity::INFO) }
if logger.level == Logger::Severity::DEBUG
  statsd = Datadog::Statsd.new(nil, nil, logger: logger)
else
  statsd = Datadog::Statsd.new
end
run HerokuDrainDatadog::HTTP::Router.new(config: HerokuDrainDatadog::Configuration.default, logger: logger, statsd: statsd).app
