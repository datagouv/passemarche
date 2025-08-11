class Admin::EditorsController < Admin::ApplicationController
  before_action :set_editor, only: %i[show edit update destroy]

  def index
    @editors = Editor.order(:name)
  end

  def show
    @statistics = {
      total_markets: @editor.public_markets.count,
      completed_markets: @editor.public_markets.where.not(completed_at: nil).count,
      active_markets: @editor.public_markets.where(completed_at: nil).count
    }
  end

  def new
    @editor = Editor.new
  end

  def edit; end

  def create
    @editor = Editor.new(editor_params)

    if @editor.save
      redirect_to admin_editor_path(@editor), notice: t('admin.editors.created')
    else
      render :new, status: :unprocessable_content
    end
  end

  def update
    if @editor.update(editor_params)
      redirect_to admin_editor_path(@editor), notice: t('admin.editors.updated')
    else
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    @editor.destroy
    redirect_to admin_editors_path, notice: t('admin.editors.deleted')
  end

  private

  def set_editor
    @editor = Editor.find(params[:id])
  end

  def editor_params
    params.expect(editor: %i[
      name client_id client_secret authorized active
      completion_webhook_url redirect_url
    ])
  end
end
