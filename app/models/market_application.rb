# frozen_string_literal: true

class MarketApplication < ApplicationRecord
  include Completable
  include Syncable

  belongs_to :public_market
  has_one :editor, through: :public_market

  has_one_attached :attestation
  has_one_attached :buyer_attestation
  has_one_attached :documents_package
  has_many :market_attribute_responses, dependent: :destroy

  accepts_nested_attributes_for :market_attribute_responses, allow_destroy: true, reject_if: :all_blank

  attr_accessor :current_validation_step

  validates :identifier, presence: true, uniqueness: true
  validates :siret, presence: true, format: { with: /\A\d{14}\z/ }
  validates :attests_no_exclusion_motifs, inclusion: { in: [true, false] }, allow_nil: false
  validates :provider_user_id, length: { maximum: 255 }, allow_nil: true
  validate :market_must_be_completed
  validate :siret_must_be_valid
  validate :nested_attributes_valid

  before_validation :generate_identifier, on: :create

  def find_authorized_document(attachment_id)
    market_attribute_responses
      .select { |r| r.class.file_attachable? }
      .flat_map(&:documents)
      .find { |doc| doc.id.to_s == attachment_id.to_s }
  end

  def update_api_status(api_name, status:, fields_filled: 0)
    with_lock do
      updated_status = (api_fetch_status || {}).dup
      updated_status[api_name] = {
        'status' => status,
        'fields_filled' => fields_filled,
        'updated_at' => Time.current.iso8601
      }
      self.api_fetch_status = updated_status
      save!
    end
  end

  def api_names_to_fetch
    public_market.market_attributes
      .where.not(api_name: nil)
      .distinct
      .pluck(:api_name)
  end

  def valid?(context = nil)
    self.current_validation_step = context
    super
  end

  def response_ids_for_step(step_name)
    return [] if step_name.blank?

    responses_for_subcategory(step_name).map(&:id)
  end

  def bodacc_exclusion_motifs
    market_attribute_responses.select do |r|
      r.source == 'auto' &&
        r.market_attribute.api_name == 'bodacc' &&
        r.value['radio_choice'] == 'yes' &&
        r.hidden?
    end
  end

  def all_security_scans_complete?
    file_responses = market_attribute_responses
      .select { |r| r.respond_to?(:documents) && r.documents.attached? }

    return true if file_responses.empty?

    file_responses.all? do |response|
      response.documents.all? { |doc| document_scan_complete?(doc) }
    end
  end

  private

  def generate_identifier
    return if identifier.present?

    self.identifier = IdentifierGenerationService.call
  end

  def market_must_be_completed
    return unless public_market

    errors.add(:public_market, 'must be completed') unless public_market.sync_completed?
  end

  def siret_must_be_valid
    return if siret.blank?
    return if SiretValidationService.call(siret)

    errors.add(:siret, 'Le numéro de SIRET saisi est invalide ou non reconnu, veuillez vérifier votre saisie.')
  end

  def nested_attributes_valid
    context = validation_context
    responses_to_validate = responses_for_context(context)
    responses_to_validate.each do |response|
      response.errors.clear
      is_valid = response.valid?(context)
      next if is_valid

      copy_response_errors_to_self(response)
    end
  end

  def responses_for_context(context)
    if context.blank? || context.to_s == 'summary'
      market_attribute_responses.to_a
    else
      responses_for_step(context)
    end
  end

  def copy_response_errors_to_self(response)
    response.errors.each do |error|
      if error.attribute == :base
        errors.add(:base, error.message)
      else
        errors.add("market_attribute_responses.#{error.attribute}", error.message)
      end
    end
  end

  def responses_for_step(step_name)
    responses_for_subcategory(step_name)
  end

  def responses_for_subcategory(subcategory_key)
    attribute_ids = public_market.market_attributes
      .where(subcategory_key: subcategory_key.to_s)
      .pluck(:id)

    market_attribute_responses.select { |r| attribute_ids.include?(r.market_attribute_id) }
  end

  def document_scan_complete?(document)
    metadata = document.blob.metadata

    metadata.key?('scan_safe') ||
      (metadata['scanner'] == 'none' && metadata.key?('scanned_at'))
  end
end
