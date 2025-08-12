# frozen_string_literal: true

class SiretValidationService < ApplicationService
  def initialize(siret)
    @siret = siret.to_s.strip
  end

  def call
    return false unless format_valid?

    luhn_valid?
  end

  private

  attr_reader :siret

  def format_valid?
    siret.match?(/\A\d{14}\z/)
  end

  def luhn_valid?
    la_poste_siret? || valid_luhn_checksum?
  end

  def la_poste_siret?
    siret.match?(/^356000000\d{5}/)
  end

  def valid_luhn_checksum?
    (luhn_checksum % 10).zero?
  end

  def luhn_checksum
    accum = 0
    siret.reverse.each_char.map(&:to_i).each_with_index do |digit, index|
      t = index.even? ? digit : digit * 2
      t -= 9 if t >= 10
      accum += t
    end
    accum
  end
end
