class BuildResource < ApplicationInteractor
  def call
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
end
