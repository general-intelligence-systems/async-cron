# async-cron

ronseal... does what it says on the tin...

Async-native cron scheduling for Ruby, built on the
[Socketry](https://github.com/socketry) async ecosystem.

## Install

```ruby
gem "async-cron"
```

## Usage

Run the scheduler inside an `Async` reactor and declare jobs with the
`at` / `in` / `every` / `cron` DSL:

```ruby
require "async/cron"

Async do
  Async::Cron.run do
    every    "5s"               do puts "tick" end           # immediately, then every 5s
    schedule "30s"              do puts "warmup done" end     # once, after 30s (-> in)
    at       "2026-01-01 09:00" do puts "happy new year" end # once, at a time
    cron     "0 9 * * 1-5"      do puts "weekday 9am" end    # wall-clock cron
  end
end
```

`run` returns a `Scheduler`; `scheduler.stop` ends the loop, `scheduler.jobs`
lists active jobs, and `scheduler.unschedule(id)` removes one. Concurrency is
bounded by `max_concurrent:` (default 28) and the poll interval by `frequency:`
(default 0.3s).

**Time basis:** `in`/`every` use a monotonic clock (`Async::Clock`), so they are
immune to NTP/DST jumps; `at`/`cron` use wall-clock time via
[`fugit`](https://github.com/floyon/fugit).

> Note: `in` is a Ruby keyword, so inside the block use `schedule("30s") { ... }`
> (it dispatches on the argument's `fugit` type) or call `self.in("30s") { ... }`
> explicitly.
