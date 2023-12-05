require "spec_helper"
require "rack/test"
require "logger"
require "datadog/statsd"
require "heroku_drain_datadog/configuration"
require "heroku_drain_datadog/http/router"
require "./spec/helpers/fake_udp_socket"

RSpec.describe HerokuDrainDatadog::HTTP::Router do
  include Rack::Test::Methods

  describe "POST /logs" do
    let(:socket) { FakeUDPSocket.new }
    let(:statsd) { Datadog::Statsd.new }

    let(:app) do
      HerokuDrainDatadog::HTTP::Router.new(
        config: HerokuDrainDatadog::Configuration.default,
        logger: Logger.new(StringIO.new),
        statsd: statsd,
      ).app
    end

    let(:output) do
      statsd.flush(sync: true)
      socket.recv.lines(chomp: true)
    end

    before { allow(UDPSocket).to receive(:new).and_return(socket) }

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
        expect(output[0]).to_not include("appname:")
      end

      context "and drain token header" do
        before do
          header "Logplex-Drain-Token", "abc123"
        end

        context "empty request body" do
          before { post "/logs" }

          it "sends 1 metric" do
            expect(output.length).to eq(1)
          end

          it "increments drain" do
            expect(output[0]).to eq("heroku.drain.request:1|c|#status:204,path:/logs")
          end

          it "is a 204" do
            expect(last_response.status).to eq(204)
            expect(last_response.body).to be_empty
          end
        end

        context "malformed request body" do
          before { post "/logs", "trolllllll" }

          it "sends 1 metric" do
            expect(output.length).to eq(1)
          end

          it "increments drain" do
            expect(output[0]).to eq("heroku.drain.request:1|c|#status:204,path:/logs")
          end

          it "is a 204" do
            expect(last_response.status).to eq(204)
            expect(last_response.body).to be_empty
          end
        end

        context "router logs" do
          before do
            post "/logs", %q{338 <158>1 2016-08-20T02:15:10.862264+00:00 host heroku router - at=info method=GET path="/assets/admin-62f13e9f7cb78a2b3e436feaedd07fd67b74cce818f3bb7cfdab1e1c05dc2f89.css" host=app.fivegoodfriends.com.au request_id=bef7f609-eceb-4684-90ce-c249e6843112 fwd="58.6.203.42,54.239.202.42" dyno=web.1 connect=0ms service=2ms status=304 bytes=112}
          end

          it "sends 3 metrics" do
            expect(output.length).to eq(3)
          end

          it "sends a histogram for connect" do
            expect(output[0]).to eq("heroku.router.connect:0.0|h|#source:web.1,dynotype:web,method:GET,status:304")
          end

          it "sends a histogram for service" do
            expect(output[1]).to eq("heroku.router.service:2.0|h|#source:web.1,dynotype:web,method:GET,status:304")
          end

          it "increments drain" do
            expect(output[2]).to eq("heroku.drain.request:1|c|#status:204,path:/logs")
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
            expect(output.length).to eq(6)
          end

          it "sends a gauge for memory_cache" do
            expect(output[0]).to eq("heroku.dyno.memory_cache:3.63|g|#source:web.1,dynotype:web")
          end

          it "sends a gauge for memory_quota" do
            expect(output[1]).to eq("heroku.dyno.memory_quota:512.0|g|#source:web.1,dynotype:web")
          end

          it "sends a gauge for memory_rss" do
            expect(output[2]).to eq("heroku.dyno.memory_rss:139.79|g|#source:web.1,dynotype:web")
          end

          it "sends a gauge for memory_swap" do
            expect(output[3]).to eq("heroku.dyno.memory_swap:11.43|g|#source:web.1,dynotype:web")
          end

          it "sends a gauge for memory_quota" do
            expect(output[4]).to eq("heroku.dyno.memory_total:154.85|g|#source:web.1,dynotype:web")
          end

          it "increments drain" do
            expect(output[5]).to eq("heroku.drain.request:1|c|#status:204,path:/logs")
          end
        end

        context "redis logs" do
          before do
            post "/logs", %q{393 <134>1 2016-09-23T07:07:54+00:00 host app heroku-redis - source=REDIS addon=redis-cubed-98704 sample#active-connections=27 sample#load-avg-1m=0 sample#load-avg-5m=0.015 sample#load-avg-15m=0.01 sample#read-iops=0 sample#write-iops=0.11282 sample#memory-total=15664876.0kB sample#memory-free=12688956.0kB sample#memory-cached=1762284.0kB sample#memory-redis=1908016bytes sample#hit-rate=0.0096774 sample#evicted-keys=0}
          end

          it "sends 13 metrics" do
            expect(output.length).to eq(13)
          end

          it "sends a gauge for the active_connections" do
            expect(output[0]).to eq("heroku.redis.active_aconnections:27|g|#addon:redis-cubed-98704")
          end

          it "sends a gauge for the load_avg_1m" do
            expect(output[1]).to eq("heroku.redis.load_avg_1m:0.0|g|#addon:redis-cubed-98704")
          end

          it "sends a gauge for the load_avg_5m" do
            expect(output[2]).to eq("heroku.redis.load_avg_5m:0.015|g|#addon:redis-cubed-98704")
          end

          it "sends a gauge for the load_avg_15m" do
            expect(output[3]).to eq("heroku.redis.load_avg_15m:0.01|g|#addon:redis-cubed-98704")
          end

          it "sends a gauge for the read_iops" do
            expect(output[4]).to eq("heroku.redis.read_iops:0.0|g|#addon:redis-cubed-98704")
          end

          it "sends a gauge for the write_iops" do
            expect(output[5]).to eq("heroku.redis.write_iops:0.11282|g|#addon:redis-cubed-98704")
          end

          it "sends a gauge for the memory_total" do
            expect(output[6]).to eq("heroku.redis.memory_total:15664876.0|g|#addon:redis-cubed-98704")
          end

          it "sends a gauge for the memory_free" do
            expect(output[7]).to eq("heroku.redis.memory_free:12688956.0|g|#addon:redis-cubed-98704")
          end

          it "sends a gauge for the memory_cached" do
            expect(output[8]).to eq("heroku.redis.memory_cached:1762284.0|g|#addon:redis-cubed-98704")
          end

          it "sends a gauge for the memory_redis" do
            expect(output[9]).to eq("heroku.redis.memory_redis:1908016.0|g|#addon:redis-cubed-98704")
          end

          it "sends a gauge for the hit_rate" do
            expect(output[10]).to eq("heroku.redis.hit_rate:0.0096774|g|#addon:redis-cubed-98704")
          end

          it "sends a gauge for the evicted_keys" do
            expect(output[11]).to eq("heroku.redis.evicted_keys:0|g|#addon:redis-cubed-98704")
          end

          it "increments drain" do
            expect(output[12]).to eq("heroku.drain.request:1|c|#status:204,path:/logs")
          end
        end

        context "postgres logs" do
          before do
            post "/logs", %q{527 <134>1 2016-08-19T11:23:29+00:00 host app heroku-postgres - source=DATABASE addon=postgres-parallel-38743 sample#current_transaction=1947 sample#db_size=8945836.0bytes sample#tables=17 sample#active-connections=3 sample#waiting-connections=0 sample#index-cache-hit-rate=0.99396 sample#table-cache-hit-rate=0.99828 sample#load-avg-1m=0.02 sample#load-avg-5m=0.005 sample#load-avg-15m=0 sample#read-iops=0 sample#write-iops=0.011458 sample#memory-total=4045592.0kB sample#memory-free=1560288.0kB sample#memory-cached=1982288.0kB sample#memory-postgres=21292kB}
          end

          it "sends 16 metrics" do
            expect(output.length).to eq(16)
          end

          it "sends a gauge for db_size" do
            expect(output[0]).to eq("heroku.postgres.db_size:8945836.0|g|#addon:postgres-parallel-38743")
          end

          it "sends a gauge for tables" do
            expect(output[1]).to eq("heroku.postgres.tables:17|g|#addon:postgres-parallel-38743")
          end

          it "sends a gauge for active_connections" do
            expect(output[2]).to eq("heroku.postgres.active_connections:3|g|#addon:postgres-parallel-38743")
          end

          it "sends a gauge for waiting_connections" do
            expect(output[3]).to eq("heroku.postgres.waiting_connections:0|g|#addon:postgres-parallel-38743")
          end

          it "sends a gauge for index_cache_hit_rate" do
            expect(output[4]).to eq("heroku.postgres.index_cache_hit_rate:0.99396|g|#addon:postgres-parallel-38743")
          end

          it "sends a gauge for table_cache_hit_rate" do
            expect(output[5]).to eq("heroku.postgres.table_cache_hit_rate:0.99828|g|#addon:postgres-parallel-38743")
          end

          it "sends a gauge for load_avg_1m" do
            expect(output[6]).to eq("heroku.postgres.load_avg_1m:0.02|g|#addon:postgres-parallel-38743")
          end

          it "sends a gauge for load_avg_5m" do
            expect(output[7]).to eq("heroku.postgres.load_avg_5m:0.005|g|#addon:postgres-parallel-38743")
          end

          it "sends a gauge for load_avg_15m" do
            expect(output[8]).to eq("heroku.postgres.load_avg_15m:0.0|g|#addon:postgres-parallel-38743")
          end

          it "sends a gauge for read_iops" do
            expect(output[9]).to eq("heroku.postgres.read_iops:0.0|g|#addon:postgres-parallel-38743")
          end

          it "sends a gauge for write_iops" do
            expect(output[10]).to eq("heroku.postgres.write_iops:0.011458|g|#addon:postgres-parallel-38743")
          end

          it "sends a gauge for memory_total" do
            expect(output[11]).to eq("heroku.postgres.memory_total:4045592.0|g|#addon:postgres-parallel-38743")
          end

          it "sends a gauge for memory_free" do
            expect(output[12]).to eq("heroku.postgres.memory_free:1560288.0|g|#addon:postgres-parallel-38743")
          end

          it "sends a gauge for memory_cached" do
            expect(output[13]).to eq("heroku.postgres.memory_cached:1982288.0|g|#addon:postgres-parallel-38743")
          end

          it "sends a gauge for memory_postgres" do
            expect(output[14]).to eq("heroku.postgres.memory_postgres:21292.0|g|#addon:postgres-parallel-38743")
          end

          it "increments drain" do
            expect(output[15]).to eq("heroku.drain.request:1|c|#status:204,path:/logs")
          end
        end

        context "postgres follower logs" do
          before do
            post(
              "/logs",
              %q{123 <456>1 2023-12-05T03:10:36+00:00 host app heroku-postgres - source=HEROKU_POSTGRESQL_GRAY addon=postgres-follower-tlw-lookout-production sample#current_transaction=70868045 sample#db_size=49030205999bytes sample#tables=243 sample#active-connections=18 sample#waiting-connections=0 sample#index-cache-hit-rate=0.9875 sample#table-cache-hit-rate=0.63474 sample#load-avg-1m=1.06 sample#load-avg-5m=1.59 sample#load-avg-15m=1.175 sample#read-iops=1830.3 sample#write-iops=23.457 sample#tmp-disk-used=543633408 sample#tmp-disk-available=72435159040 sample#memory-total=3944484kB sample#memory-free=92388kB sample#memory-cached=3261980kB sample#memory-postgres=165416kB sample#follower-lag-commits=9 sample#wal-percentage-used=0.06451981873320072},
            )
          end

          it "sends a gauge for follower_lag_commits" do
            expect(output).to include("heroku.postgres.follower_lag_commits:9|g|#addon:postgres-follower-tlw-lookout-production")
          end
        end

        context "and drain env var" do
          it "can be a single tag" do
            with_env("DRAIN_TAGS_FOR_abc123", "service:myapp") do
              post "/logs", %q{338 <158>1 2016-08-20T02:15:10.862264+00:00 host heroku router - at=info method=GET path="/assets/admin-62f13e9f7cb78a2b3e436feaedd07fd67b74cce818f3bb7cfdab1e1c05dc2f89.css" host=app.fivegoodfriends.com.au request_id=bef7f609-eceb-4684-90ce-c249e6843112 fwd="58.6.203.42,54.239.202.42" dyno=web.1 connect=0ms service=2ms status=304 bytes=112}
              expect(output[0]).to eq("heroku.router.connect:0.0|h|#service:myapp,source:web.1,dynotype:web,method:GET,status:304")
            end
          end

          it "can be many tags" do
            with_env("DRAIN_TAGS_FOR_abc123", "env:production,service:myapp") do
              post "/logs", %q{338 <158>1 2016-08-20T02:15:10.862264+00:00 host heroku router - at=info method=GET path="/assets/admin-62f13e9f7cb78a2b3e436feaedd07fd67b74cce818f3bb7cfdab1e1c05dc2f89.css" host=app.fivegoodfriends.com.au request_id=bef7f609-eceb-4684-90ce-c249e6843112 fwd="58.6.203.42,54.239.202.42" dyno=web.1 connect=0ms service=2ms status=304 bytes=112}
              expect(output[0]).to eq("heroku.router.connect:0.0|h|#env:production,service:myapp,source:web.1,dynotype:web,method:GET,status:304")
            end
          end

          private

          def with_env(key, value, &block)
            begin
              key = "DRAIN_TAGS_FOR_abc123"
              original_value = ENV[key]
              ENV[key] = value
              yield
            ensure
              ENV[key] = original_value
            end
          end
        end
      end
    end
  end
end
