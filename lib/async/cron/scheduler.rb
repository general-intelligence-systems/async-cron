# frozen_string_literal: true

module Async
  module Cron
    # A fibre-based scheduler. Polls its jobs every `frequency` seconds inside an
    # Async reactor, firing due jobs through an Async::Semaphore that bounds how
    # many run concurrently.
    #
    #   Async::Cron.run do
    #     every "5s" do ... end
    #     cron  "0 9 * * *" do ... end
    #   end
    #
    # When called inside an existing reactor, #start returns immediately (the
    # loop runs as a child task). At the top level, Async {} runs the reactor and
    # blocks until the scheduler is stopped.
    class Scheduler
      def self.run(frequency: 0.3, max_concurrent: 28, &block)
        new(frequency:, max_concurrent:).tap do |scheduler|
          scheduler.instance_eval(&block) if block
          scheduler.start
        end
      end

      def initialize(frequency: 0.3, max_concurrent: 28)
        @frequency = frequency
        @jobs = {}
        @semaphore = Async::Semaphore.new(max_concurrent)
        @task = nil
      end

      def start
        @task = Async do |task|
          loop do
            tick
            task.sleep(@frequency)
          end
        end
      end

      def stop = @task&.stop

      def wait = @task&.wait

      def at(time, callable = nil, **opts, &block)   = add(AtJob.new(time, callable || block), opts)
      def in(dur, callable = nil, **opts, &block)    = add(InJob.new(dur, callable || block), opts)
      def every(spec, callable = nil, **opts, &block) = add(build_every(spec, callable || block), opts)
      def cron(line, callable = nil, **opts, &block) = add(CronJob.new(line, callable || block), opts)

      def schedule(arg, callable = nil, **opts, &block)
        case Fugit.parse(arg)
        when Fugit::Cron     then cron(arg, callable, **opts, &block)
        when Fugit::Duration then self.in(arg, callable, **opts, &block)
        else                      at(arg, callable, **opts, &block)
        end
      end

      def unschedule(id) = @jobs.delete(id)
      def jobs           = @jobs.values

      private

      def tick
        wall = EtOrbi::EoTime.now
        mono = Async::Clock.now

        # Snapshot: a triggered job may add/remove jobs mid-iteration.
        @jobs.values.each do |job|
          next unless job.due?(wall:, mono:)

          @semaphore.async { job.trigger(wall) }
          job.advance(wall:, mono:)
        end

        @jobs.reject! { |_, job| job.finished? }
      end

      # "wednesday" -> cron, "5s" -> interval. Fugit decides, not us.
      def build_every(spec, callable)
        Fugit.parse(spec).is_a?(Fugit::Cron) ? CronJob.new(spec, callable) : EveryJob.new(spec, callable)
      end

      def add(job, opts)
        @jobs[job.id] = job
        opts[:job] ? job : job.id
      end
    end
  end
end
