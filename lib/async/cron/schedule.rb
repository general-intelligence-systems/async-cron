# frozen_string_literal: true

module Async
  module Cron
    # A set of jobs, built from the scheduling DSL. A Schedule just holds jobs
    # (and a semaphore bounding how many fire at once). It has no notion of a
    # clock or a loop -- Async::Cron.run iterates these jobs and runs the due
    # ones; Async::Cron.loop does that on repeat.
    #
    #   schedule = Async::Cron::Schedule.new do
    #     every "5s" do ... end
    #     cron  "0 9 * * *" do ... end
    #   end
    class Schedule
      attr_reader :semaphore

      def initialize(max_concurrent: 28, &block)
        @jobs = {}
        @semaphore = Async::Semaphore.new(max_concurrent)
        instance_eval(&block) if block
      end

      def at(time, callable = nil, **opts, &block)    = add(AtJob.new(time, callable || block), opts)
      def after(dur, callable = nil, **opts, &block)  = add(AfterJob.new(dur, callable || block), opts)
      def every(spec, callable = nil, **opts, &block) = add(build_every(spec, callable || block), opts)
      def cron(line, callable = nil, **opts, &block)  = add(CronJob.new(line, callable || block), opts)

      def unschedule(id) = @jobs.delete(id)
      def jobs           = @jobs.values

      private

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
