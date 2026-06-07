# frozen_string_literal: true

require_relative "../job"

module Async
  module Cron
    # Runs once after a delay, measured on the monotonic clock, then finishes.
    # The deadline is fixed lazily on the first poll the scheduler shows it.
    class InJob < Job
      def initialize(dur, callable)
        super(callable)
        @delay = to_sec(dur)
        @deadline = nil
      end

      def due?(mono:, **)
        @deadline ||= mono + @delay
        !@finished && mono >= @deadline
      end

      def advance(**) = @finished = true
    end
  end
end
