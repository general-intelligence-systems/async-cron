# frozen_string_literal: true

require_relative "../job"

module Async
  module Cron
    # Runs every interval (seconds, monotonic), firing immediately on the first
    # poll and then once per interval. Never finishes on its own.
    class EveryJob < Job
      def initialize(spec, callable)
        super(callable)
        @interval = to_sec(spec)
        @next = nil
      end

      def due?(mono:, **)
        @next ||= mono
        mono >= @next
      end

      def advance(mono:, **)
        @next ||= mono
        @next += @interval
      end
    end
  end
end
