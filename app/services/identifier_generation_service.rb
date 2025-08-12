# frozen_string_literal: true

class IdentifierGenerationService < ApplicationService
  SUFFIX_LENGTH = 12
  MICROSECOND_MULTIPLIER = 1_000_000
  RANDOM_COMPONENT_RANGE = 1000

  def call
    build_identifier
  end

  private

  def build_identifier
    now = Time.zone.now
    year = now.year
    suffix = generate_unique_suffix(now)
    "VR-#{year}-#{suffix}"
  end

  def generate_unique_suffix(time)
    unique_number = (time.to_f * MICROSECOND_MULTIPLIER).to_i + SecureRandom.random_number(RANDOM_COMPONENT_RANGE)
    unique_number.to_s(36).upcase.rjust(SUFFIX_LENGTH, '0')[-SUFFIX_LENGTH..]
  end
end
