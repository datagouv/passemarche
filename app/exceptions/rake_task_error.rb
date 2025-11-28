# frozen_string_literal: true

class RakeTaskError < StandardError
  def initialize(message, exit_code: 1)
    super(message)
    @exit_code = exit_code
  end

  attr_reader :exit_code
end
