# frozen_string_literal: true

require_relative "../job"

module Async
  module Cron
    # Runs once at a specific wall-clock time, then finishes.
    class AtJob < Job
      def initialize(time, callable)
        super(callable)
        @at = to_eotime(time)
      end

      def due?(wall:, **) = !@finished && wall >= @at

      def advance(**) = @finished = true
    end
  end
end
