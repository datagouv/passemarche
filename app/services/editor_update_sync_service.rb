# frozen_string_literal: true

class EditorUpdateSyncService < ApplicationService
  def initialize(editor)
    @editor = editor
  end

  def call
    if editor.doorkeeper_application
      update_doorkeeper_application!
    else
      create_doorkeeper_application!
    end
  end

  private

  attr_reader :editor

  def update_doorkeeper_application!
    editor.doorkeeper_application.tap do |app|
      app.update!(
        name: editor.name,
        secret: editor.client_secret,
        scopes: 'api_access api_read api_write'
      )
    end
  end

  def create_doorkeeper_application!
    CustomDoorkeeperApplication.create!(
      name: editor.name,
      uid: editor.client_id,
      secret: editor.client_secret,
      redirect_uri: '',
      scopes: 'api_access api_read api_write'
    )
  end
end
