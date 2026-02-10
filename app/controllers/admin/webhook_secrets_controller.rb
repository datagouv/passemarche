class Admin::WebhookSecretsController < Admin::ApplicationController
  before_action :require_admin_role!
  before_action :set_editor

  def create
    @editor.generate_webhook_secret
    if @editor.save
      redirect_to edit_admin_editor_path(@editor), notice: t('admin.editors.webhook_secret_generated')
    else
      redirect_to edit_admin_editor_path(@editor), alert: t('admin.editors.webhook_secret_error')
    end
  end

  private

  def set_editor
    @editor = Editor.find(params[:editor_id])
  end
end
