module WebhookSyncable
  extend ActiveSupport::Concern

  def skip_delivery?(entity)
    entity.sync_completed?
  end

  def before_delivery_callback(entity)
    entity.update!(sync_status: :sync_processing)
  end

  def entity_webhook_url(entity)
    entity.editor.completion_webhook_url
  end

  def entity_webhook_secret(entity)
    entity.editor.webhook_secret
  end

  def on_success_callback(entity)
    entity.update!(sync_status: :sync_completed)
  end

  def on_error_callback(entity)
    entity.update!(sync_status: :sync_failed)
  end
end
