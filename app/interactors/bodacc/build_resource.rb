# frozen_string_literal: true

class Bodacc::BuildResource < ApplicationInteractor
  def call
    analyze_records
    build_bundled_data
  end

  protected

  def analyze_records
    if context.records.blank?
      context.liquidation_detected = false
      context.dirigeant_a_risque = false
    else
      analyze_legal_situations
    end
  end

  def build_bundled_data
    has_exclusions = context.liquidation_detected || context.dirigeant_a_risque
    resource = Resource.new(resource_attributes)

    context.bundled_data = BundledData.new(
      data: resource,
      context: {
        liquidation_detected: context.liquidation_detected,
        dirigeant_a_risque: context.dirigeant_a_risque,
        has_exclusions:,
        exclusions_summary: build_exclusions_summary
      }
    )
  end

  def resource_attributes
    {
      liquidation_judiciaire: build_radio_with_file_and_text(
        context.liquidation_detected,
        'Liquidation détectée par Bodacc'
      ),
      faillite_interdiction: build_radio_with_file_and_text(
        context.dirigeant_a_risque,
        'Dirigeant à risque détecté par Bodacc'
      )
    }
  end

  def build_radio_with_file_and_text(detected, text)
    if detected
      { 'radio_choice' => 'yes', 'text' => text }
    else
      { 'radio_choice' => 'no' }
    end
  end

  private

  def analyze_legal_situations
    context.liquidation_detected = liquidation?(context.records)
    context.dirigeant_a_risque = dirigeant_a_risque?(context.records)
  end

  def liquidation?(records)
    records.any? do |record|
      famille_avis = record['familleavis_lib'].to_s.downcase
      return true if famille_avis.include?('procédure collective')

      if record['jugement'].present?
        jugement_data = begin
          JSON.parse(record['jugement'])
        rescue StandardError
          {}
        end
        nature_jugement = jugement_data['nature'].to_s.downcase
        return true if nature_jugement.include?('liquidation')
      end

      false
    end
  end

  def dirigeant_a_risque?(records)
    records.any? do |record|
      if record['listepersonnes'].present?
        personnes_data = begin
          JSON.parse(record['listepersonnes'])
        rescue StandardError
          {}
        end
        contenu = personnes_data.to_s.downcase
        mots_cles_risque = ['faillite personnelle', 'interdiction de gérer', 'banqueroute']
        return true if mots_cles_risque.any? { |mot| contenu.include?(mot) }
      end

      false
    end
  end

  def build_exclusions_summary
    exclusions = []
    exclusions << 'Liquidation judiciaire détectée' if context.liquidation_detected
    exclusions << 'Dirigeant à risque détecté' if context.dirigeant_a_risque
    exclusions
  end
end
