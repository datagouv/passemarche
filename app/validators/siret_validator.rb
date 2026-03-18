# frozen_string_literal: true

class SiretValidator < ActiveModel::EachValidator
  def self.valid?(siret)
    siret = siret.to_s.strip
    return false unless siret.match?(/\A\d{14}\z/)

    la_poste_siret?(siret) || valid_luhn_checksum?(siret)
  end

  def validate_each(record, attribute, value)
    return if self.class.valid?(value)

    record.errors.add(attribute, :invalid)
  end

  def self.la_poste_siret?(siret)
    siret.match?(/^356000000\d{5}/)
  end

  def self.valid_luhn_checksum?(siret)
    (luhn_checksum(siret) % 10).zero?
  end

  def self.luhn_checksum(siret)
    accum = 0
    siret.reverse.each_char.map(&:to_i).each_with_index do |digit, index|
      t = index.even? ? digit : digit * 2
      t -= 9 if t >= 10
      accum += t
    end
    accum
  end

  private_class_method :la_poste_siret?, :valid_luhn_checksum?, :luhn_checksum
end
