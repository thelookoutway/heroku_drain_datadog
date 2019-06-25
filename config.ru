$LOAD_PATH.unshift File.expand_path("../lib", __FILE__)
require "heroku_drain_datadog"
require "logger"
require "datadog/statsd"

run HerokuDrainDatadog::HTTP::Router.new(
  config: HerokuDrainDatadog::Configuration.default,
  logger: Logger.new(STDOUT).tap { |l| l.level = ENV.fetch("LOG_LEVEL", "INFO") },
  statsd: Datadog::Statsd.new,
).app
