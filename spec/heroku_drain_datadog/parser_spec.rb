require "spec_helper"
require "heroku_drain_datadog/parser"

RSpec.describe HerokuDrainDatadog::Parser do
  let(:router_log) { %q{338 <158>1 2016-08-20T02:15:10.862264+00:00 host heroku router - at=info method=GET path="/assets/admin-62f13e9f7cb78a2b3e436feaedd07fd67b74cce818f3bb7cfdab1e1c05dc2f89.css" host=app.fivegoodfriends.com.au request_id=bef7f609-eceb-4684-90ce-c249e6843112 fwd="58.6.203.42,54.239.202.42" dyno=web.1 connect=0ms service=2ms status=304 bytes=112} }
  let(:dyno_log) { %q{334 <45>1 2016-08-19T11:23:01.581780+00:00 host heroku web.1 - source=web.1 dyno=heroku.54241834.4b88c98d-6243-4194-af49-8db9b53be371 sample#memory_total=154.85MB sample#memory_rss=139.79MB sample#memory_cache=3.63MB sample#memory_swap=11.43MB sample#memory_pgpgin=80522pages sample#memory_pgpgout=53004pages sample#memory_quota=512.00MB} }
  let(:redis_log) { %q{393 <134>1 2016-09-23T07:07:54+00:00 host app heroku-redis - source=REDIS addon=redis-cubed-98704 sample#active-connections=27 sample#load-avg-1m=0 sample#load-avg-5m=0.015 sample#load-avg-15m=0.01 sample#read-iops=0 sample#write-iops=0.11282 sample#memory-total=15664876.0kB sample#memory-free=12688956.0kB sample#memory-cached=1762284.0kB sample#memory-redis=1908016bytes sample#hit-rate=0.0096774 sample#evicted-keys=0} }
  let(:postgres_log) { %q{527 <134>1 2016-08-19T11:23:29+00:00 host app heroku-postgres - source=DATABASE addon=postgres-parallel-38743 sample#current_transaction=1947 sample#db_size=8945836.0bytes sample#tables=17 sample#active-connections=3 sample#waiting-connections=0 sample#index-cache-hit-rate=0.99396 sample#table-cache-hit-rate=0.99828 sample#load-avg-1m=0.02 sample#load-avg-5m=0.005 sample#load-avg-15m=0 sample#read-iops=0 sample#write-iops=0.011458 sample#memory-total=4045592.0kB sample#memory-free=1560288.0kB sample#memory-cached=1982288.0kB sample#memory-postgres=21292kB} }

  context "dyno logs" do
    let(:log_entry) { subject.call(dyno_log).first }

    it "is dyno service" do
      expect(log_entry.service).to eq(:dyno)
    end

    it "has data" do
      expect(log_entry.data).to eq({
        "source"=>"web.1",
        "dyno" => "heroku.54241834.4b88c98d-6243-4194-af49-8db9b53be371",
        "sample#memory_cache" => "3.63MB",
        "sample#memory_pgpgin" => "80522pages",
        "sample#memory_pgpgout" => "53004pages",
        "sample#memory_quota" => "512.00MB",
        "sample#memory_rss" => "139.79MB",
        "sample#memory_swap" => "11.43MB",
        "sample#memory_total" => "154.85MB",
      })
    end
  end

  context "router logs" do
    let(:log_entry) { subject.call(router_log).first }

    it "is a router service" do
      expect(log_entry.service).to eq(:router)
    end

    it "has data" do
      expect(log_entry.data).to eq({
        "at" => "info",
        "method" => "GET",
        "path" => %q{"/assets/admin-62f13e9f7cb78a2b3e436feaedd07fd67b74cce818f3bb7cfdab1e1c05dc2f89.css"},
        "host" => "app.fivegoodfriends.com.au",
        "request_id" => "bef7f609-eceb-4684-90ce-c249e6843112",
        "fwd" => %q{"58.6.203.42,54.239.202.42"},
        "dyno" => "web.1",
        "connect" => "0ms",
        "service" => "2ms",
        "status" => "304",
        "bytes" => "112"
      })
    end
  end

  context "redis logs" do
    let(:log_entry) { subject.call(redis_log).first }

    it "is a postgres service" do
      expect(log_entry.service).to eq(:redis)
    end

    it "has data" do
      expect(log_entry.data).to eq({
        "source" => "REDIS",
        "addon"=>"redis-cubed-98704",
        "sample#active-connections" => "27",
        "sample#load-avg-1m" => "0",
        "sample#load-avg-5m" => "0.015",
        "sample#load-avg-15m" => "0.01",
        "sample#read-iops" => "0",
        "sample#write-iops" => "0.11282",
        "sample#memory-total" => "15664876.0kB",
        "sample#memory-free" => "12688956.0kB",
        "sample#memory-cached" => "1762284.0kB",
        "sample#memory-redis" => "1908016bytes",
        "sample#hit-rate" => "0.0096774",
        "sample#evicted-keys" => "0",
      })
    end
  end

  context "postgres logs" do
    let(:log_entry) { subject.call(postgres_log).first }

    it "is a postgres service" do
      expect(log_entry.service).to eq(:postgres)
    end

    it "has data" do
      expect(log_entry.data).to eq({
        "source" => "DATABASE",
        "addon"=>"postgres-parallel-38743",
        "sample#current_transaction" => "1947",
        "sample#db_size" => "8945836.0bytes",
        "sample#tables" => "17",
        "sample#active-connections" => "3",
        "sample#waiting-connections" => "0",
        "sample#index-cache-hit-rate" => "0.99396",
        "sample#table-cache-hit-rate" => "0.99828",
        "sample#load-avg-1m" => "0.02",
        "sample#load-avg-5m" => "0.005",
        "sample#load-avg-15m" => "0",
        "sample#read-iops" => "0",
        "sample#write-iops" => "0.011458",
        "sample#memory-total" => "4045592.0kB",
        "sample#memory-free" => "1560288.0kB",
        "sample#memory-cached" => "1982288.0kB",
        "sample#memory-postgres" => "21292kB",
      })
    end
  end

  it "parses multiple lines" do
    log_entries = subject.call([dyno_log, router_log, postgres_log].join("\n"))
    expect(log_entries.size).to eq(3)
    expect(log_entries[0].service).to eq(:dyno)
    expect(log_entries[1].service).to eq(:router)
    expect(log_entries[2].service).to eq(:postgres)
  end

  it "has a timestamp" do
    log_entry = subject.call(dyno_log).first
    expect(log_entry.timestamp).to eq(Time.parse("2016-08-19 11:23:01.581780000 +0000"))
  end

  it "discards blank links" do
    log_entries = subject.call("")
    expect(log_entries).to be_empty
  end

  it "discards postgres checkpoint" do
    log_entries = subject.call(%q{2016-08-12T12:19:06+00:00 app[postgres.10]: [DATABASE] [4717-1] LOG:  checkpoint starting: time})
    expect(log_entries).to be_empty
  end

  it "discards rails" do
    log_entries = subject.call(%q{2016-08-12T12:22:51.476419+00:00 app[web.1]: I, [2016-08-12T12:22:51.476293 #3]  INFO -- : [46add18f-75b9-4dcf-9943-782082f3407e] Started GET "/session/new" for 124.170.158.158 at 2016-08-12 12:22:51 +0000})
    expect(log_entries).to be_empty
  end
end
