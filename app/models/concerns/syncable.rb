module Syncable
  extend ActiveSupport::Concern

  included do
    enum :sync_status, {
      sync_pending: 0,
      sync_processing: 1,
      sync_completed: 2,
      sync_failed: 3
    }, default: :sync_pending, validate: true
  end

  def sync_in_progress?
    sync_pending? || sync_processing?
  end
end
