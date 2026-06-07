# frozen_string_literal: true

require "test_helper"

class ScheduleTest < Minitest::Test
  def test_dsl_registers_jobs_and_returns_ids
    schedule = Async::Cron::Schedule.new
    id = schedule.every("5s") { :noop }

    assert_kind_of String, id
    assert_equal 1, schedule.jobs.size
    assert_kind_of Async::Cron::EveryJob, schedule.jobs.first

    schedule.unschedule(id)
    assert_empty schedule.jobs
  end

  def test_block_constructor_builds_jobs
    schedule = Async::Cron::Schedule.new do
      every("5s") { :noop }
      cron("0 9 * * *") { :noop }
    end

    assert_equal 2, schedule.jobs.size
  end

  def test_job_option_returns_the_job
    schedule = Async::Cron::Schedule.new
    job = schedule.cron("0 9 * * *", job: true) { :noop }
    assert_kind_of Async::Cron::CronJob, job
  end

  def test_dsl_builds_each_job_type
    schedule = Async::Cron::Schedule.new
    schedule.cron("0 9 * * *") { :noop }
    schedule.after("5s") { :noop }
    schedule.at("2999-01-01 12:00") { :noop }

    classes = schedule.jobs.map(&:class).sort_by(&:name)
    assert_equal [Async::Cron::AfterJob, Async::Cron::AtJob, Async::Cron::CronJob], classes
  end

  def test_run_with_block_builds_schedule_and_fires_due_jobs
    count = 0
    Async do
      # every fires immediately, so a single poll runs it once.
      Async::Cron.run { every("5s") { count += 1 } }
    end

    assert_equal 1, count
  end

  def test_run_returns_the_schedule_for_reuse
    schedule = Async::Cron::Schedule.new { every("0.02s") { :noop } }

    returned = nil
    Async { returned = Async::Cron.run(schedule) }

    assert_same schedule, returned
  end

  def test_run_drops_finished_jobs
    schedule = Async::Cron::Schedule.new { after("0s") { :noop } }

    Async { Async::Cron.run(schedule) }

    assert_empty schedule.jobs
  end

  def test_loop_runs_repeatedly
    count = 0
    Async do |task|
      schedule = Async::Cron::Schedule.new { every("0.02s") { count += 1 } }
      looper = task.async { Async::Cron.loop(schedule, frequency: 0.01) }
      sleep(0.15)
      looper.stop
    end

    assert_operator count, :>=, 3, "expected several fires, got #{count}"
  end

  def test_max_concurrent_caps_inflight
    inflight = 0
    peak = 0
    Async do |task|
      schedule = Async::Cron::Schedule.new(max_concurrent: 2) do
        every("0.01s") do
          inflight += 1
          peak = [peak, inflight].max
          sleep(0.05)
          inflight -= 1
        end
      end
      looper = task.async { Async::Cron.loop(schedule, frequency: 0.01) }
      sleep(0.2)
      looper.stop
    end

    assert_operator peak, :>=, 1
    assert_operator peak, :<=, 2, "peak in-flight #{peak} exceeded max_concurrent 2"
  end
end
