# frozen_string_literal: true

class AddInvitationTokenDigestToVersions < ActiveRecord::Migration[8.1]
  def change
    add_column :versions, :invitation_token_digest, :string
    add_index :versions, :invitation_token_digest
  end
end
