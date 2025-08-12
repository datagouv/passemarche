# frozen_string_literal: true

class ApplicationServiceObject
  attr_reader :errors, :result

  def initialize(...)
    @errors = {}
    @result = nil
  end

  def perform
    raise NotImplementedError, 'Subclasses must implement #perform'
  end

  def success?
    @errors.blank?
  end

  def failure?
    !success?
  end

  protected

  def add_error(key, message)
    (@errors[key] ||= []) << message
  end
end
