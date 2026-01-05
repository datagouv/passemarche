# frozen_string_literal: true

class Insee::MapInseeApiData < MapApiData
  private

  def create_or_update_response(market_attribute)
    response = find_or_initialize_response(market_attribute)
    value = extract_value_from_resource(market_attribute)
    return if skip_nil_value_for_new_response?(response, value)

    super
  end

  def skip_nil_value_for_new_response?(response, value)
    response.new_record? && value.nil?
  end
end
