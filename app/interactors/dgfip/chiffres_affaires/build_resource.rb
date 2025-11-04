# frozen_string_literal: true

class Dgfip::ChiffresAffaires::BuildResource < BuildResource
  protected

  def resource_attributes
    {
      chiffres_affaires_data: build_chiffres_affaires_data
    }
  end

  def valid_json?
    # For turnover data, an empty array [] is a valid response
    # (means that no fiscal year was found)
    begin
      return true if json_body.is_a?(Array)
    rescue JSON::ParserError
      return false
    end

    super
  end

  private

  def chiffres_affaires_par_annee
    # The structure is: [{ 'data' => { 'chiffre_affaires' => X, 'date_fin_exercice' => Y } }]
    exercices = json_body || []

    # Sort by fiscal year end date descending and take the 3 most recent
    exercices
      .filter_map { |exercice| exercice['data'] }
      .sort_by { |data| -Date.parse(data['date_fin_exercice']).year }
      .first(3)
      .map do |data|
        {
          annee: Date.parse(data['date_fin_exercice']).year,
          chiffre_affaires: data['chiffre_affaires'],
          date_fin_exercice: data['date_fin_exercice']
        }
      end
  end

  def build_chiffres_affaires_data
    data = chiffres_affaires_par_annee

    result = {
      'year_1' => { 'turnover' => nil, 'market_percentage' => nil, 'fiscal_year_end' => nil },
      'year_2' => { 'turnover' => nil, 'market_percentage' => nil, 'fiscal_year_end' => nil },
      'year_3' => { 'turnover' => nil, 'market_percentage' => nil, 'fiscal_year_end' => nil },
      '_api_fields' => {}
    }

    data.each_with_index do |year_data, index|
      break if index >= 3

      year_key = "year_#{index + 1}"
      result[year_key] = {
        'turnover' => year_data[:chiffre_affaires].to_i,
        'market_percentage' => nil,
        'fiscal_year_end' => year_data[:date_fin_exercice]
      }

      # Mark which fields came from API for this year
      result['_api_fields'][year_key] = %w[turnover fiscal_year_end]
    end

    result.to_json
  end
end
