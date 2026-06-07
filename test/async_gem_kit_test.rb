# frozen_string_literal: true

require "test_helper"

class AsyncGemKitTest < Minitest::Test
  def test_version
    refute_nil Async::GemKit::VERSION
  end
end
