# Getting Started

This guide explains how to get started with `async-cron`, an async-native
scheduler built on the [Socketry](https://github.com/socketry) ecosystem.

## Installation

Add the gem to your project:

~~~bash
$ bundle add async-cron
~~~

## Usage

Declare jobs with the `at` / `in` / `every` / `cron` DSL, then drive the
schedule from your own loop inside an `Async` reactor:

~~~ruby
require "async/cron"

Async do
  Async::Cron.loop do
    every    "5s"               do puts "tick" end            # immediately, then every 5s
    schedule "30s"              do puts "warmup done" end     # once, after 30s
    at       "2026-01-01 09:00" do puts "happy new year" end  # once, at a time
    cron     "0 9 * * 1-5"      do puts "weekday 9am" end     # wall-clock cron
  end
end
~~~

`Async::Cron.run` is a single poll — it runs whatever is due right now — and the
block builds a {ruby Async::Cron::Schedule}. `Async::Cron.loop` is just
`loop { run; sleep }`, so you can equally own the loop yourself:

~~~ruby
schedule = Async::Cron::Schedule.new { every("5s") { puts "tick" } }
loop { Async::Cron.run(schedule); sleep 1 }
~~~

## Time Basis

`in` and `every` are measured on a monotonic clock (`Async::Clock`), so they are
immune to NTP/DST jumps. `at` and `cron` use wall-clock time via
[`fugit`](https://github.com/floyon/fugit).
