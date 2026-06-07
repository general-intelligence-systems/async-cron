# frozen_string_literal: true

require "test_helper"

# Jobs are pure with respect to time, so we drive wall:/mono: by hand -- no
# reactor, no sleeping.
class JobsTest < Minitest::Test
  NOOP = -> {}

  def test_at_job_is_one_shot
    at = EtOrbi::EoTime.now + 100
    job = Async::Cron::AtJob.new(at, NOOP)

    refute job.due?(wall: EtOrbi::EoTime.now, mono: 0.0)
    assert job.due?(wall: at, mono: 0.0)

    job.advance(wall: at, mono: 0.0)
    assert job.finished?
    refute job.due?(wall: at + 1, mono: 0.0)
  end

  def test_at_job_coerces_time_string
    job = Async::Cron::AtJob.new("2999-01-01 12:00:00", NOOP)
    refute job.due?(wall: EtOrbi::EoTime.now, mono: 0.0)
  end

  def test_in_job_delays_on_monotonic_clock
    job = Async::Cron::InJob.new("5s", NOOP)

    refute job.due?(mono: 0.0, wall: nil)   # deadline pinned to 0 + 5
    refute job.due?(mono: 4.9, wall: nil)
    assert job.due?(mono: 5.0, wall: nil)

    job.advance(mono: 5.0, wall: nil)
    assert job.finished?
    refute job.due?(mono: 6.0, wall: nil)
  end

  def test_every_job_fires_immediately_then_each_interval
    job = Async::Cron::EveryJob.new("5s", NOOP)

    assert job.due?(mono: 0.0, wall: nil)   # immediate
    job.advance(mono: 0.0, wall: nil)

    refute job.due?(mono: 3.0, wall: nil)
    assert job.due?(mono: 5.0, wall: nil)
    refute job.finished?
  end

  def test_every_job_accepts_numeric_interval
    job = Async::Cron::EveryJob.new(2, NOOP)
    assert job.due?(mono: 0.0, wall: nil)
    job.advance(mono: 0.0, wall: nil)
    assert job.due?(mono: 2.0, wall: nil)
  end

  def test_cron_job_uses_wall_clock
    job = Async::Cron::CronJob.new("*/1 * * * *", NOOP)
    nxt = job.instance_variable_get(:@next)

    assert nxt > EtOrbi::EoTime.now
    refute job.due?(wall: EtOrbi::EoTime.now - 1, mono: 0.0)
    assert job.due?(wall: nxt, mono: 0.0)

    job.advance(wall: nxt, mono: 0.0)
    assert_operator job.instance_variable_get(:@next), :>, nxt
    refute job.finished?
  end

  def test_invalid_duration_raises
    assert_raises(ArgumentError) { Async::Cron::EveryJob.new("definitely not a duration", NOOP) }
  end

  def test_blank_callable_raises
    assert_raises(ArgumentError) { Async::Cron::EveryJob.new("5s", nil) }
  end

  def test_trigger_swallows_errors
    job = Async::Cron::EveryJob.new("5s", -> { raise "boom" })
    # Should not raise out of trigger.
    assert_nil job.trigger(EtOrbi::EoTime.now)
  end

  def test_trigger_passes_fire_time_when_arity_allows
    seen = nil
    job = Async::Cron::EveryJob.new("5s", ->(t) { seen = t })
    now = EtOrbi::EoTime.now
    job.trigger(now)
    assert_equal now, seen
  end
end
