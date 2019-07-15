# Heroku Drain for Datadog [![Build status](https://badge.buildkite.com/194bc494c91e01c19fc754b5c78f792770e707b9ecfd81bae2.svg)](https://buildkite.com/fivegoodfriends/heroku-drain-datadog)

A micro Ruby app that drains logs from Heroku, extracts the metrics, and forwards them to Datadog. Supported services are:

* Heroku Router
* Heroku Postgres
* Heroku Redis
* Dyno

By forwarding metrics to Datadog you could:

* Set an alert when dynos are low on free memory.
* Set an alert when Redis is approaching the maximum memory limit allowed by the current plan.
* Graph the dyno's memory usage and load for each type of dyno (e.g. Worker, Web)
* Graph the request queue

See `config/default.yml` for a full list of metrics and how they map between Heroku and Datadog.

### Example Dashboards

![](https://user-images.githubusercontent.com/19860/60142182-0d2b3900-97fc-11e9-9f0b-11405a2d5312.png)
![](https://user-images.githubusercontent.com/19860/60142183-0d2b3900-97fc-11e9-88a4-52ca32f62a6f.png)

## System Dependencies

* Ruby 2.6.2
* [Heroku Buildpack for DataDog Agent](https://github.com/DataDog/heroku-buildpack-datadog.git)

## Setup

### Deploying the Drain

To deploy the drain:

    $ git clone https://github.com/fivegoodfriends/heroku-drain-datadog.git
    $ heroku apps create
    $ heroku buildpacks:add https://github.com/DataDog/heroku-buildpack-datadog.git
    $ heroku buildpacks:add heroku/ruby
    $ heroku config:set DD_API_KEY=<YOUR_DATADOG_API_KEY>
    $ heroku config:set DRAIN_PASSWORD=<YOUR_DRAIN_PASSWORD>
    $ heroku config:set RACK_ENV=production
    $ git push heroku master

The drain itself will not use the dyno, dynotype, and appname tags to avoid conflicting with forwarded metrics.

### Instrumenting an App

To instrument an app:

    $ heroku labs:enable log-runtime-metrics --app <MY-APP>
    $ heroku drains:add https://user:<YOUR_DRAIN_PASSWORD>@<YOUR_APP>.herokuapp.com/logs --app <MY-APP>

All forwarded metrics will be tagged with their appname, dyno, and dynotype. To set additional tags:

    $ heroku config:set DRAIN_TAGS_FOR_<LOGPLEX_DRAIN_TOKEN>="env:production,service:app" -a <DRAIN-APP>

The drain token can be found by running `$ heroku drains -a <MY-APP>`

## Development

Setup the project:

    $ bin/setup

Run the specs:

    $ bin/rspec

Run the server and send a log entry:

    $ DRAIN_PASSWORD=secret LOG_LEVEL=debug ./bin/puma -C config/puma.rb
    $ curl -u :secret -X POST -d "338 <158>1 2016-08-20T02:15:10.862264+00:00 host heroku router - at=info method=GET path="/assets/admin-62f13e9f7cb78a2b3e436feaedd07fd67b74cce818f3bb7cfdab1e1c05dc2f89.css" host=app.fivegoodfriends.com.au request_id=bef7f609-eceb-4684-90ce-c249e6843112 fwd="58.6.203.42,54.239.202.42" dyno=web.1 connect=0ms service=2ms status=304 bytes=112" http://localhost:3000/logs

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/fivegoodfriends/heroku_drain_datadog.

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
