# frozen_string_literal: true

require_relative "../job"

module Async
  module Cron
    # Runs on a wall-clock cron schedule (via fugit). Never finishes on its own.
    class CronJob < Job
      def initialize(line, callable)
        super(callable)
        @cron = Fugit.do_parse_cron(line)
        @next = @cron.next_time(EtOrbi::EoTime.now)
      end

      def due?(wall:, **) = wall >= @next

      def advance(wall:, **) = @next = @cron.next_time(wall)
    end
  end
end
