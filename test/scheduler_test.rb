# frozen_string_literal: true

require "test_helper"

class SchedulerTest < Minitest::Test
  def test_dsl_registers_jobs_and_returns_ids
    scheduler = Async::Cron::Scheduler.new
    id = scheduler.every("5s") { :noop }

    assert_kind_of String, id
    assert_equal 1, scheduler.jobs.size
    assert_kind_of Async::Cron::EveryJob, scheduler.jobs.first

    scheduler.unschedule(id)
    assert_empty scheduler.jobs
  end

  def test_job_option_returns_the_job
    scheduler = Async::Cron::Scheduler.new
    job = scheduler.cron("0 9 * * *", job: true) { :noop }
    assert_kind_of Async::Cron::CronJob, job
  end

  def test_schedule_dispatches_on_fugit_type
    scheduler = Async::Cron::Scheduler.new
    scheduler.schedule("0 9 * * *") { :noop } # cron
    scheduler.schedule("5s") { :noop }        # duration -> in
    scheduler.schedule("2999-01-01 12:00") { :noop } # time -> at

    classes = scheduler.jobs.map(&:class).sort_by(&:name)
    assert_equal [Async::Cron::AtJob, Async::Cron::CronJob, Async::Cron::InJob], classes
  end

  def test_every_runs_repeatedly_in_reactor
    count = 0
    Async do |task|
      scheduler = Async::Cron.run(frequency: 0.01) { every("0.02s") { count += 1 } }
      task.sleep(0.15)
      scheduler.stop
    end

    assert_operator count, :>=, 3, "expected several fires, got #{count}"
  end

  def test_max_concurrent_caps_inflight
    inflight = 0
    peak = 0
    Async do |task|
      scheduler = Async::Cron.run(frequency: 0.01, max_concurrent: 2) do
        every("0.01s") do
          inflight += 1
          peak = [peak, inflight].max
          Async::Task.current.sleep(0.05)
          inflight -= 1
        end
      end
      task.sleep(0.2)
      scheduler.stop
    end

    assert_operator peak, :>=, 1
    assert_operator peak, :<=, 2, "peak in-flight #{peak} exceeded max_concurrent 2"
  end
end
