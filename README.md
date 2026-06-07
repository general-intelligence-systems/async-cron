# async-cron

ronseal... does what it says on the tin...

Async-native cron scheduling for Ruby, built on the
[Socketry](https://github.com/socketry) async ecosystem.

## Install

```ruby
gem "async-cron"
```

## Usage

Declare jobs with the `at` / `in` / `every` / `cron` DSL, then drive the
schedule from your own loop inside an `Async` reactor:

```ruby
require "async/cron"

Async do
  Async::Cron.loop do
    every "5s"               do puts "tick" end            # immediately, then every 5s
    after "30s"              do puts "warmup done" end     # once, after 30s
    at    "2026-01-01 09:00" do puts "happy new year" end  # once, at a time
    cron  "0 9 * * 1-5"      do puts "weekday 9am" end     # wall-clock cron
  end
end
```

`Async::Cron.run` is one poll: it checks every job against the current time and
runs whatever is due. The block builds a `Schedule` — `Async::Cron.run(&block)`
is just `Async::Cron.run(Schedule.new(&block))` — so you own the loop:

```ruby
Async do
  Async::Cron::Schedule.new { every("5s") { puts "tick" } }.tap do |schedule|
    loop do
      Async::Cron.run(schedule)   # fire what's due, right now
      sleep 1                     # cooperative inside the reactor
    end
  end
end
```

`Async::Cron.loop(schedule, frequency: 0.3)` is exactly `loop { run; sleep }`.
A `Schedule` exposes `#jobs` and `#unschedule(id)`; concurrency is bounded by
`Schedule.new(max_concurrent: 28)`.

**Time basis:** `after`/`every` use a monotonic clock (`Async::Clock`), so they
are immune to NTP/DST jumps; `at`/`cron` use wall-clock time via
[`fugit`](https://github.com/floyon/fugit).
