# frozen_string_literal: true

module Async
  module Cron
    # Base class for all scheduled jobs.
    #
    # Jobs are pure with respect to time: the Scheduler injects the current
    # wall-clock (EtOrbi::EoTime) and monotonic (Async::Clock) readings into
    # #due? and #advance, so jobs never read a clock themselves and can be
    # unit-tested by hand-feeding time.
    class Job
      attr_reader :id

      def initialize(callable)
        raise ArgumentError, "a callable or block is required" unless callable

        @callable = callable
        @id = SecureRandom.uuid
        @finished = false
      end

      # Run the job's callable, passing the fire time when it accepts an
      # argument. Errors are logged and swallowed so one bad run never stops
      # the scheduler.
      def trigger(time)
        @callable.arity.zero? ? @callable.call : @callable.call(time)
      rescue StandardError => e
        Console.error(self, e)
      end

      def finished? = @finished

      private

      # Coerce a duration/interval spec to a Float of seconds.
      def to_sec(spec)
        case spec
        when Numeric then spec.to_f
        when Fugit::Duration then spec.to_sec
        else
          parsed = Fugit.parse(spec.to_s)
          raise ArgumentError, "not a duration: #{spec.inspect}" unless parsed.respond_to?(:to_sec)

          parsed.to_sec
        end
      end

      # Coerce a point in time to an EtOrbi::EoTime.
      def to_eotime(time)
        return time if time.is_a?(EtOrbi::EoTime)

        if time.is_a?(String)
          parsed = Fugit.parse(time)
          return parsed if parsed.is_a?(EtOrbi::EoTime)
        end

        EtOrbi.make_time(time)
      end
    end
  end
end
