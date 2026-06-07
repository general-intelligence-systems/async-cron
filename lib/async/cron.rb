# frozen_string_literal: true

require "securerandom"

require "async"
require "async/clock"
require "async/semaphore"
require "console"
require "fugit"

require_relative "cron/version"
require_relative "cron/job"
require_relative "cron/jobs/at_job"
require_relative "cron/jobs/after_job"
require_relative "cron/jobs/every_job"
require_relative "cron/jobs/cron_job"
require_relative "cron/schedule"

module Async
  module Cron
    # Check a schedule against the current time and run whatever is due, once.
    # The caller owns the loop:
    #
    #   schedule = Async::Cron::Schedule.new { every("5s") { ... } }
    #   loop { Async::Cron.run(schedule); sleep 1 }
    #
    # A block is shorthand for building the schedule -- Async::Cron.run(&block)
    # is Async::Cron.run(Schedule.new(&block)) -- handy for a one-shot poll.
    def self.run(schedule = nil, &block)
      schedule ||= Schedule.new(&block)

      wall = EtOrbi::EoTime.now
      mono = Async::Clock.now

      schedule.jobs.each do |job|
        if job.due?(wall:, mono:)
          if Async::Task.current?
            schedule.semaphore.async { job.trigger(wall) }
          else
            job.trigger(wall)
          end
          job.advance(wall:, mono:)
        end

        schedule.unschedule(job.id) if job.finished?
      end

      schedule
    end

    # loop { run } -- build the schedule once, then poll forever, sleeping
    # `frequency` seconds between polls:
    #
    #   Async { Async::Cron.loop { every("5s") { ... } } }
    def self.loop(schedule = nil, frequency: 0.3, &block)
      schedule ||= Schedule.new(&block)

      Kernel.loop do
        run(schedule)
        sleep(frequency)
      end
    end
  end
end
