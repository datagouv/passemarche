# frozen_string_literal: true

class CotisationRetraite < ApplicationOrganizer
  def self.call(context = {})
    context[:api_name] ||= 'cotisation_retraite'

    cibtp_result = call_organizer_safely(Cibtp, context)
    cnetp_result = call_organizer_safely(Cnetp, context)

    merged_context = merge_api_results(context, cibtp_result, cnetp_result)

    result = CotisationRetraite::MergeResources.call(merged_context)

    return result if result.failure?

    MapApiData.call(result)
  end

  def self.call_organizer_safely(organizer_class, context)
    organizer_class.call(context.dup)
  rescue StandardError => e
    Rails.logger.warn "[CotisationRetraite] #{organizer_class.name} failed: #{e.message}"
    # Return a failed context-like object
    Interactor::Context.build(failure?: true, error: e.message)
  end

  def self.merge_api_results(original_context, cibtp_result, cnetp_result)
    merged_data = extract_documents(cibtp_result, cnetp_result)

    Interactor::Context.build(
      original_context.merge(
        bundled_data: BundledData.new(data: Resource.new(merged_data))
      )
    )
  end

  def self.extract_documents(cibtp_result, cnetp_result)
    {}.tap do |merged_data|
      merged_data[:cibtp_document] = extract_cibtp_document(cibtp_result)
      merged_data[:cnetp_document] = extract_cnetp_document(cnetp_result)
      merged_data.compact!
    end
  end

  def self.extract_cibtp_document(result)
    return nil unless result.success? && result.bundled_data&.data.respond_to?(:cibtp_document)

    result.bundled_data.data.cibtp_document
  end

  def self.extract_cnetp_document(result)
    return nil unless result.success? && result.bundled_data&.data.respond_to?(:cnetp_document)

    result.bundled_data.data.cnetp_document
  end
end
