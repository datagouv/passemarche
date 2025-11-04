# frozen_string_literal: true

class ApiBlockStatusPresenter
  STATUS_COLORS = {
    'pending' => 'var(--blue-france-sun-113-625)',
    'processing' => 'var(--blue-france-sun-113-625)',
    'completed' => '#18753C',
    'failed' => '#B34000'
  }.freeze

  def initialize(market_application)
    @market_application = market_application
  end

  def blocks
    @blocks ||= begin
      all_blocks = blocks_config.map do |block_config|
        ApiBlock.new(block_config, @market_application)
      end
      all_blocks.reject { |block| block.apis.empty? }
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
      @market_application = market_application
      @apis = filter_relevant_apis(block_config[:apis])
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

    def completed_count
      api_statuses.count { |s| s[:status] == 'completed' }
    end

    def total_count
      apis.length
    end

    def all_completed?
      completed_count == total_count
    end

    def done_message
      if all_completed?
        I18n.t('candidate.market_applications.api_data_recovery_status.messages.all_success')
      else
        I18n.t('candidate.market_applications.api_data_recovery_status.messages.partial_success')
      end
    end

    def status_count_class
      all_completed? ? 'api-status-count--success' : 'api-status-count--warning'
    end

    def api_statuses
      apis.map do |api_name|
        api_status = individual_api_status(api_name)
        {
          name: api_name,
          status: api_status,
          color: status_color(api_status)
        }
      end
    end

    private

    def individual_api_status(api_name)
      api_status = api_status_for(api_name)
      return 'pending' if api_status.nil? || api_status == 'pending'
      return 'processing' if api_status == 'processing'
      return 'completed' if api_status == 'completed'

      'failed'
    end

    def status_color(status)
      STATUS_COLORS[status]
    end

    def api_data_for(api_name)
      @market_application.api_fetch_status&.dig(api_name.to_s.downcase) || default_api_status
    end

    def api_completed?(api_name)
      api_status_for(api_name) == 'completed'
    end

    def api_failed?(api_name)
      api_status_for(api_name) == 'failed'
    end

    def api_processing?(api_name)
      api_status_for(api_name) == 'processing'
    end

    def api_pending?(api_name)
      api_status_for(api_name) == 'pending'
    end

    def api_status_for(api_name)
      api_data_for(api_name)['status']
    end

    def default_api_status
      { 'status' => 'pending', 'fields_filled' => 0 }
    end

    def filter_relevant_apis(configured_apis)
      market_apis = @market_application.api_names_to_fetch.map(&:downcase)
      configured_apis.select { |api| market_apis.include?(api.downcase) }
    end
  end
end
