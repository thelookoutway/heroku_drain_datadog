require "spec_helper"
require "rack/test"
require "logger"
require "statsd"
require "heroku_drain_datadog/configuration"
require "heroku_drain_datadog/router"

RSpec.describe HerokuDrainDatadog::Router do
  include Rack::Test::Methods

  describe "POST /logs" do
    let(:statsd) { Statsd.new }

    let(:app) do
      HerokuDrainDatadog::Router.new(
        config: HerokuDrainDatadog::Configuration.default,
        logger: Logger.new(StringIO.new),
        statsd: statsd,
      ).app
    end

    # Batch so we can set expectations on the buffered metrics.
    around do |example|
      statsd.batch do
        example.run
      end
    end

    it "is a 401 with bad credentials" do
      basic_authorize "", "badbabad"
      post "/logs"
      expect(last_response.status).to eq(401)
    end

    context "with genuine credentials" do
      before do
        basic_authorize "", "secret"
      end

      it "does not the drain or app in the tags" do
        post "/logs", %q{338 <158>1 2016-08-20T02:15:10.862264+00:00 host heroku router - at=info method=GET path="/assets/admin-62f13e9f7cb78a2b3e436feaedd07fd67b74cce818f3bb7cfdab1e1c05dc2f89.css" host=app.fivegoodfriends.com.au request_id=bef7f609-eceb-4684-90ce-c249e6843112 fwd="58.6.203.42,54.239.202.42" dyno=web.1 connect=0ms service=2ms status=304 bytes=112}
        expect(statsd.buffer[0]).to_not include("drain:")
        expect(statsd.buffer[0]).to_not include("app:")
      end

      context "and drain token header" do
        before do
          header "Logplex-Drain-Token", "abc123"
        end

        context "empty request body" do
          it "doesn't send any metrics" do
            expect(statsd.buffer.length).to eq(0)
          end

          it "is a 204" do
            post "/logs"
            expect(last_response.status).to eq(204)
            expect(last_response.body).to be_empty
          end
        end

        context "malformed request body" do
          it "doesn't send any metrics" do
            expect(statsd.buffer.length).to eq(0)
          end

          it "is a 204" do
            post "/logs", "trolllllll"
            expect(last_response.status).to eq(204)
            expect(last_response.body).to be_empty
          end
        end

        context "router logs" do
          before do
            post "/logs", %q{338 <158>1 2016-08-20T02:15:10.862264+00:00 host heroku router - at=info method=GET path="/assets/admin-62f13e9f7cb78a2b3e436feaedd07fd67b74cce818f3bb7cfdab1e1c05dc2f89.css" host=app.fivegoodfriends.com.au request_id=bef7f609-eceb-4684-90ce-c249e6843112 fwd="58.6.203.42,54.239.202.42" dyno=web.1 connect=0ms service=2ms status=304 bytes=112}
          end

          it "sends 3 metrics" do
            expect(statsd.buffer.length).to eq(3)
          end

          it "sends a histogram for connect" do
            expect(statsd.buffer[0]).to eq("heroku.router.connect:0.0|h|#drain:abc123,dyno:web.1,method:GET,host:app.fivegoodfriends.com.au,path:/assets/admin-62f13e9f7cb78a2b3e436feaedd07fd67b74cce818f3bb7cfdab1e1c05dc2f89.css,status:304")
          end

          it "sends a histogram for service" do
            expect(statsd.buffer[1]).to eq("heroku.router.service:2.0|h|#drain:abc123,dyno:web.1,method:GET,host:app.fivegoodfriends.com.au,path:/assets/admin-62f13e9f7cb78a2b3e436feaedd07fd67b74cce818f3bb7cfdab1e1c05dc2f89.css,status:304")
          end

          it "increments drain" do
            expect(statsd.buffer[2]).to eq("heroku.drain.request:1|c|#status:204,host:example.org,path:/logs")
          end

          it "is a 204" do
            expect(last_response.status).to eq(204)
            expect(last_response.body).to be_empty
          end
        end

        context "dyno memory logs" do
          before do
            post "/logs", %q{334 <45>1 2016-08-19T11:23:01.581780+00:00 host heroku web.1 - source=web.1 dyno=heroku.54241834.4b88c98d-6243-4194-af49-8db9b53be371 sample#memory_total=154.85MB sample#memory_rss=139.79MB sample#memory_cache=3.63MB sample#memory_swap=11.43MB sample#memory_pgpgin=80522pages sample#memory_pgpgout=53004pages sample#memory_quota=512.00MB}
          end

          it "sends 6 metrics" do
            expect(statsd.buffer.length).to eq(6)
          end

          it "sends a gauge for memory_cache" do
            expect(statsd.buffer[0]).to eq("heroku.dyno.memory_cache:3.63|g|#drain:abc123,source:web.1")
          end

          it "sends a gauge for memory_quota" do
            expect(statsd.buffer[1]).to eq("heroku.dyno.memory_quota:512.0|g|#drain:abc123,source:web.1")
          end

          it "sends a gauge for memory_rss" do
            expect(statsd.buffer[2]).to eq("heroku.dyno.memory_rss:139.79|g|#drain:abc123,source:web.1")
          end

          it "sends a gauge for memory_swap" do
            expect(statsd.buffer[3]).to eq("heroku.dyno.memory_swap:11.43|g|#drain:abc123,source:web.1")
          end

          it "sends a gauge for memory_quota" do
            expect(statsd.buffer[4]).to eq("heroku.dyno.memory_total:154.85|g|#drain:abc123,source:web.1")
          end

          it "increments drain" do
            expect(statsd.buffer[5]).to eq("heroku.drain.request:1|c|#status:204,host:example.org,path:/logs")
          end
        end

        context "postgres logs" do
          before do
            post "/logs", %q{527 <134>1 2016-08-19T11:23:29+00:00 host app heroku-postgres - source=DATABASE sample#current_transaction=1947 sample#db_size=8945836.0bytes sample#tables=17 sample#active-connections=3 sample#waiting-connections=0 sample#index-cache-hit-rate=0.99396 sample#table-cache-hit-rate=0.99828 sample#load-avg-1m=0.02 sample#load-avg-5m=0.005 sample#load-avg-15m=0 sample#read-iops=0 sample#write-iops=0.011458 sample#memory-total=4045592.0kB sample#memory-free=1560288.0kB sample#memory-cached=1982288.0kB sample#memory-postgres=21292kB}
          end

          it "sends 16 metrics" do
            expect(statsd.buffer.length).to eq(16)
          end

          it "sends a gauge for db_size" do
            expect(statsd.buffer[0]).to eq("heroku.postgres.db_size:8945836.0|g|#drain:abc123")
          end

          it "sends a gauge for tables" do
            expect(statsd.buffer[1]).to eq("heroku.postgres.tables:17.0|g|#drain:abc123")
          end

          it "sends a gauge for active connections" do
            expect(statsd.buffer[2]).to eq("heroku.postgres.active_connections:3|g|#drain:abc123")
          end

          it "sends a gauge for waiting_connections" do
            expect(statsd.buffer[3]).to eq("heroku.postgres.waiting_connections:0|g|#drain:abc123")
          end

          it "sends a gauge for index_cache_hit_rate" do
            expect(statsd.buffer[4]).to eq("heroku.postgres.index_cache_hit_rate:0.99396|g|#drain:abc123")
          end

          it "sends a gauge for table_cache_hit_rate" do
            expect(statsd.buffer[5]).to eq("heroku.postgres.table_cache_hit_rate:0.99828|g|#drain:abc123")
          end

          it "sends a gauge for load_avg_1m" do
            expect(statsd.buffer[6]).to eq("heroku.postgres.load_avg_1m:0.02|g|#drain:abc123")
          end

          it "sends a gauge for load_avg_5m" do
            expect(statsd.buffer[7]).to eq("heroku.postgres.load_avg_5m:0.005|g|#drain:abc123")
          end

          it "sends a gauge for load_avg_15m" do
            expect(statsd.buffer[8]).to eq("heroku.postgres.load_avg_15m:0.0|g|#drain:abc123")
          end

          it "sends a gauge for read_iops" do
            expect(statsd.buffer[9]).to eq("heroku.postgres.read_iops:0.0|g|#drain:abc123")
          end

          it "sends a gauge for write_iops" do
            expect(statsd.buffer[10]).to eq("heroku.postgres.write_iops:0.011458|g|#drain:abc123")
          end

          it "sends a gauge for memory_total" do
            expect(statsd.buffer[11]).to eq("heroku.postgres.memory_total:4045592.0|g|#drain:abc123")
          end

          it "sends a gauge for memory_free" do
            expect(statsd.buffer[12]).to eq("heroku.postgres.memory_free:1560288.0|g|#drain:abc123")
          end

          it "sends a gauge for memory_cached" do
            expect(statsd.buffer[13]).to eq("heroku.postgres.memory_cached:1982288.0|g|#drain:abc123")
          end

          it "sends a gauge for memory_postgres" do
            expect(statsd.buffer[14]).to eq("heroku.postgres.memory_postgres:21292.0|g|#drain:abc123")
          end

          it "increments drain" do
            expect(statsd.buffer[15]).to eq("heroku.drain.request:1|c|#status:204,host:example.org,path:/logs")
          end
        end

        context "and drain env var" do
          around do |example|
            begin
              key = "DRAIN_abc123"
              original_value = ENV[key]
              ENV[key] = "myapp"
              example.run
            ensure
              ENV[key] = original_value
            end
          end

          it "includes the app's name in the tags" do
            post "/logs", %q{338 <158>1 2016-08-20T02:15:10.862264+00:00 host heroku router - at=info method=GET path="/assets/admin-62f13e9f7cb78a2b3e436feaedd07fd67b74cce818f3bb7cfdab1e1c05dc2f89.css" host=app.fivegoodfriends.com.au request_id=bef7f609-eceb-4684-90ce-c249e6843112 fwd="58.6.203.42,54.239.202.42" dyno=web.1 connect=0ms service=2ms status=304 bytes=112}
            expect(statsd.buffer[0]).to eq("heroku.router.connect:0.0|h|#drain:abc123,app:myapp,dyno:web.1,method:GET,host:app.fivegoodfriends.com.au,path:/assets/admin-62f13e9f7cb78a2b3e436feaedd07fd67b74cce818f3bb7cfdab1e1c05dc2f89.css,status:304")
          end
        end
      end
    end
  end
end
