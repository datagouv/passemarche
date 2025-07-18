# frozen_string_literal: true

class CustomDoorkeeperApplication < ApplicationRecord
  include ::Doorkeeper::Orm::ActiveRecord::Mixins::Application

  self.table_name = 'oauth_applications'

  def self.by_uid_and_secret(uid, secret)
    app = super
    return nil unless app

    # Validate Editor authorization status
    editor = Editor.find_by(client_id: uid)
    return nil unless editor&.authorized_and_active?

    app
  end
end
