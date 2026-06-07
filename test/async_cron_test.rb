# frozen_string_literal: true

require "test_helper"

class AsyncCronTest < Minitest::Test
  def test_version
    refute_nil Async::Cron::VERSION
  end
end
