# frozen_string_literal: true

class EditorSyncService < ApplicationService
  def initialize(editor)
    @editor = editor
  end

  def call
    editor.doorkeeper_application || create_doorkeeper_application!
  end

  private

  attr_reader :editor

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
