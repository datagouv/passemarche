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
  validates :siret, format: { with: /\A\d{14}\z/ }, allow_blank: true
  validates :subject_to_prohibition, inclusion: { in: [true, false], allow_nil: true }
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

  def prohibition_declared?
    subject_to_prohibition == true
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

    step_attributes = public_market.market_attributes
      .where(subcategory_key: step_name.to_s)

    attribute_ids = step_attributes.pluck(:id)

    market_attribute_responses
      .select { |r| attribute_ids.include?(r.market_attribute_id) }
      .map(&:id)
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
    # Use validation context to determine which responses to validate
    # validation_context is the current wizard step (e.g., :market_information)
    # If nil, validate all responses (e.g., at summary step)
    responses_to_validate = if validation_context.blank?
                              # No context = validate everything (summary step)
                              market_attribute_responses
                            else
                              # Get only responses for this step's form fields
                              responses_for_step(validation_context)
                            end

    responses_to_validate.each do |response|
      next if response.valid?

      response.errors.each do |error|
        errors.add("market_attribute_responses.#{error.attribute}", error.message)
      end
    end
  end

  def responses_for_step(step_name)
    # Query attributes that belong to this step (matched by subcategory_key)
    step_attributes = public_market.market_attributes
      .where(subcategory_key: step_name.to_s)

    attribute_ids = step_attributes.pluck(:id)

    # Return only responses for this step's attributes
    market_attribute_responses.select { |r| attribute_ids.include?(r.market_attribute_id) }
  end
end
