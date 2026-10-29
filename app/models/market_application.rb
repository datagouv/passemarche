# frozen_string_literal: true

class MarketApplication < ApplicationRecord
  include Completable
  include Syncable
  include GroupementWizardSteps

  has_paper_trail on: %i[update], only: [:completed_at]

  belongs_to :public_market
  belongs_to :user, optional: true
  has_one :editor, through: :public_market
  has_one :grouping_member, inverse_of: :market_application

  enum :application_mode, { solo: 0, groupement: 1, mixte: 2 }, validate: { allow_nil: true }

  has_one_attached :attestation
  has_one_attached :buyer_attestation
  has_one_attached :documents_package
  has_many :market_attribute_responses, dependent: :destroy
  has_many :market_application_lots, dependent: :destroy
  has_many :lots, through: :market_application_lots

  accepts_nested_attributes_for :market_attribute_responses, allow_destroy: true, reject_if: :all_blank

  attr_accessor :current_validation_step

  normalizes :siret, with: ->(siret) { siret.strip }

  validates :identifier, presence: true, uniqueness: true
  validates :siret, presence: true, siret: true
  validates :attests_no_exclusion_motifs, inclusion: { in: [true, false] }, allow_nil: false
  validates :provider_user_id, length: { maximum: 255 }, allow_nil: true
  validate :market_must_be_completed
  validate :nested_attributes_valid
  validate :application_mode_immutable, on: :update

  before_validation :generate_identifier, on: :create

  scope :for_user, ->(user) { where(user:) }
  scope :for_siret, ->(siret) { where(siret:) }
  scope :outside_grouping, -> { where.missing(:grouping_member).where(application_mode: [nil, :solo, :mixte]) }
  scope :matching_mode, ->(mode) { where(application_mode: mode.blank? || mode.to_s == 'solo' ? [nil, :solo] : mode) }

  def in_progress?
    !completed?
  end

  def accessible_by?(user)
    user_id.nil? || user_id == user.id
  end

  def part_of_grouping?
    grouping_member.present?
  end

  def co_traitant_of_grouping?
    !!grouping_member&.co_traitant?
  end

  def grouping_submitted?
    !!grouping_member&.grouping&.submitted?
  end

  def locked?
    completed? || grouping_submitted?
  end

  def submitted_to_platform?
    part_of_grouping? ? grouping_submitted? : completed?
  end

  def submitted_to_platform_at
    return unless submitted_to_platform?

    part_of_grouping? ? grouping_member.grouping.submitted_at : completed_at
  end

  def deletable?
    !completed? && !groupement? && !part_of_grouping?
  end

  def groupement_counterpart
    return nil if groupement?

    MarketApplication.where(public_market:, siret:, application_mode: :groupement, user_id:).where.not(id:).first
  end

  def solo_counterpart
    return nil if solo?

    MarketApplication.where(public_market:, siret:, application_mode: :solo, user_id:).where.not(id:).first
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
    applicable_market_attributes.filter_map(&:api_name).uniq
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

  def selected_lot_types
    declared_lot_types.compact.uniq
  end

  def multi_type_selected_lots?
    selected_lot_types.size > 1
  end

  def applicable_market_type_codes
    lot_types = declared_lot_types
    return public_market.effective_market_type_codes if lot_types.empty? || lot_types.any?(&:nil?)

    lot_codes = lot_types.map(&:code).uniq
    public_market.defense_industry? ? lot_codes + ['defense'] : lot_codes
  end

  def applicable_market_attributes
    type_codes = applicable_market_type_codes
    market_attributes_with_types.select do |market_attribute|
      attribute_codes = market_attribute.market_types.map(&:code)
      attribute_codes.empty? || attribute_codes.intersect?(type_codes)
    end
  end

  def applicable_market_attribute_ids
    applicable_market_attributes.map(&:id)
  end

  def applicable_market_attribute_responses
    applicable_ids = applicable_market_attribute_ids
    market_attribute_responses.select { |response| applicable_ids.include?(response.market_attribute_id) }
  end

  def purge_inapplicable_data!
    market_attribute_responses.where.not(market_attribute_id: applicable_market_attribute_ids).destroy_all
    market_attribute_responses.reset

    applicable_api_fetch_status = (api_fetch_status || {}).slice(*api_names_to_fetch)
    update!(api_fetch_status: applicable_api_fetch_status) if applicable_api_fetch_status != api_fetch_status
  end

  def all_security_scans_complete?
    file_responses = applicable_market_attribute_responses
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

  def application_mode_immutable
    return unless application_mode_in_database.present? && will_save_change_to_application_mode?

    errors.add(:application_mode, :immutable)
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
      applicable_market_attribute_responses
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
    attribute_ids = applicable_market_attributes
      .select { |market_attribute| market_attribute.subcategory_key == subcategory_key.to_s }
      .map(&:id)

    market_attribute_responses.select { |r| attribute_ids.include?(r.market_attribute_id) }
  end

  def document_scan_complete?(document)
    metadata = document.blob.metadata

    metadata.key?('scan_safe') ||
      (metadata['scanner'] == 'none' && metadata.key?('scanned_at'))
  end

  def declared_lot_types
    declared_lots.includes(:market_type, :platform_market_type).map(&:effective_market_type)
  end

  def market_attributes_with_types
    public_market.market_attributes.includes(:market_types).to_a
  end
end
