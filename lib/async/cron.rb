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
require_relative "cron/jobs/in_job"
require_relative "cron/jobs/every_job"
require_relative "cron/jobs/cron_job"
require_relative "cron/scheduler"

module Async
  module Cron
    # Build a scheduler, evaluate the optional block against it, start it, and
    # return it. See Scheduler for the DSL (at/in/every/cron/schedule).
    def self.run(...)
      Scheduler.run(...)
    end
  end
end
