# frozen_string_literal: true

class PrefixVersionsWhodunnit < ActiveRecord::Migration[8.1]
  class MigrationVersion < ApplicationRecord
    self.table_name = 'versions'
  end

  def up
    MigrationVersion.where.not(whodunnit: nil).find_each do |version|
      version.update!(whodunnit: prefixed_whodunnit(version))
    end
  end

  def down
    MigrationVersion.where.not(whodunnit: nil).find_each do |version|
      version.update!(whodunnit: legacy_whodunnit(version.whodunnit))
    end
  end

  private

  def prefixed_whodunnit(version)
    whodunnit = version.whodunnit
    return whodunnit if whodunnit.start_with?('admin_user_', 'user_', 'buyer_')
    return whodunnit.sub('candidate:', 'user_') if whodunnit.start_with?('candidate:')
    return "admin_user_#{whodunnit}" if version.item_type == 'MarketAttribute'

    "buyer_#{whodunnit}"
  end

  def legacy_whodunnit(whodunnit)
    return whodunnit.delete_prefix('admin_user_') if whodunnit.start_with?('admin_user_')
    return whodunnit.delete_prefix('buyer_') if whodunnit.start_with?('buyer_')

    whodunnit.sub('user_', 'candidate:')
  end
end
