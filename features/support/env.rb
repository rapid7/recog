# frozen_string_literal: true

require 'aruba/cucumber'

Before do
  @dirs = ['features/data']
  @aruba_timeout_seconds = 30
end
