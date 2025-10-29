# frozen_string_literal: true

class ApiBlockStatusPresenter
  def initialize(market_application)
    @market_application = market_application
  end

  def blocks
    @blocks ||= blocks_config.map do |block_config|
      ApiBlock.new(block_config, @market_application)
    end
  end

  def all_blocks_done?
    blocks.all?(&:done?)
  end

  def current_block
    blocks.find(&:loading?)
  end

  def completed_blocks_count
    blocks.count(&:completed?)
  end

  def failed_blocks_count
    blocks.count(&:failed?)
  end

  def overall_status_message
    return success_message if all_blocks_done? && failed_blocks_count.zero?
    return partial_failure_message if all_blocks_done? && failed_blocks_count.positive?

    in_progress_message
  end

  def success_message
    'L\'ensemble des informations et documents ont été récupérés'
  end

  private

  def partial_failure_message
    "#{failed_blocks_count} bloc(s) n'ont pas pu être récupérés. " \
      'Vous pourrez saisir ces informations manuellement.'
  end

  def in_progress_message
    'Récupération en cours, veuillez patienter...'
  end

  def blocks_config
    I18n.t('candidate.market_applications.api_data_recovery_status.blocks')
      .transform_values(&:symbolize_keys)
      .values
      .sort_by { |block| block[:order] }
  end

  class ApiBlock
    attr_reader :name, :description, :icon, :apis

    def initialize(block_config, market_application)
      @name = block_config[:name]
      @description = block_config[:description]
      @icon = block_config[:icon]
      @apis = block_config[:apis]
      @success_message_template = block_config[:success_message]
      @error_message_template = block_config[:error_message]
      @market_application = market_application
    end

    def status
      return 'loading' if apis.any? { |api| api_pending?(api) || api_processing?(api) }
      return 'failed' if apis.any? { |api| api_failed?(api) }

      'completed'
    end

    def loading?
      status == 'loading'
    end

    def completed?
      status == 'completed'
    end

    def failed?
      status == 'failed'
    end

    def done?
      completed? || failed?
    end

    def success_message
      @success_message_template
    end

    def error_message
      @error_message_template
    end

    private

    def api_status_for(api_name)
      @market_application.api_fetch_status&.dig(api_name.to_s.downcase) || default_api_status
    end

    def api_completed?(api_name)
      api_status_for(api_name)['status'] == 'completed'
    end

    def api_failed?(api_name)
      api_status_for(api_name)['status'] == 'failed'
    end

    def api_processing?(api_name)
      api_status_for(api_name)['status'] == 'processing'
    end

    def api_pending?(api_name)
      api_status_for(api_name)['status'] == 'pending'
    end

    def default_api_status
      { 'status' => 'pending', 'fields_filled' => 0 }
    end
  end
end
