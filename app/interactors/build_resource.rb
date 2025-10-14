class BuildResource < ApplicationInteractor
  def call
    context.fail!(error: 'Invalid JSON response') unless valid_json?

    resource = resource_klass.new(resource_attributes)
    context.bundled_data = BundledData.new(data: resource, context: {})
  end

  protected

  def resource_attributes
    raise NotImplementedError
  end

  def resource_klass
    Resource
  end

  def json_body
    @json_body ||= JSON.parse(context.response.body).fetch('data', {})
  end

  def valid_json?
    json_body.present?
  rescue JSON::ParserError
    false
  end
end
