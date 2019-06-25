# Heroku Drain for Datadog [![Build status](https://badge.buildkite.com/194bc494c91e01c19fc754b5c78f792770e707b9ecfd81bae2.svg)](https://buildkite.com/fivegoodfriends/heroku-drain-datadog)

A micro Ruby app that drains logs from Heroku, derives the metrics, and sends them to Datadog. Supported services are:

* Heroku Router
* Heroku Postgres
* Heroku Redis
* Dyno

See `config/default.yml` for a full list of metrics.

## System Dependencies

* Ruby 2.6.2
* [Heroku Buildpack for DataDog Agent](https://github.com/DataDog/heroku-buildpack-datadog.git)

## Deploying

First, deploy the drain:

    $ git clone https://github.com/fivegoodfriends/heroku-drain-datadog.git
    $ heroku apps create
    $ heroku buildpacks:add https://github.com/DataDog/heroku-buildpack-datadog.git
    $ heroku buildpacks:add heroku/ruby
    $ heroku labs:enable runtime-dyno-metadata
    $ heroku config:set DD_API_KEY=<YOUR_DATADOG_API_KEY>
    $ heroku config:set DRAIN_PASSWORD=<YOUR_DRAIN_PASSWORD>
    $ heroku config:set RACK_ENV=production
    $ git push heroku master

Then, add runtime metrics and the drain to an existing app:

    $ heroku labs:enable log-runtime-metrics --app <MY-APP>
    $ heroku drains:add https://user:<YOUR_DRAIN_PASSWORD>@<YOUR_APP>.herokuapp.com/logs --app <MY-APP>

Then, optionally map the drain token to any number of tags:

    $ heroku config:set DRAIN_TAGS_FOR_<LOGPLEX_DRAIN_TOKEN>="env:production,service:app" -a <DRAIN-APP>

## Development

Setup the project:

    $ bin/setup

Run the specs:

    $ bin/rspec

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/fivegoodfriends/heroku_drain_datadog.

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
