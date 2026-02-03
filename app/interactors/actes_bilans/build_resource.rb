# frozen_string_literal: true

class ActesBilans::BuildResource < BuildResource
  protected

  def resource_attributes
    {
      actes_et_bilans: bilan_urls
    }
  end

  def valid_json?
    raw_bilans_data.is_a?(Array)
  rescue JSON::ParserError
    false
  end

  private

  def raw_bilans_data
    @raw_bilans_data ||= JSON.parse(context.response.body).dig('data', 'bilans')
  end

  def bilan_urls
    return [] unless raw_bilans_data.is_a?(Array)

    raw_bilans_data.filter_map { |bilan| bilan['url'] }
  end
end
