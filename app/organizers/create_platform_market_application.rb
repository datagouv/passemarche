# frozen_string_literal: true

class CreatePlatformMarketApplication < ApplicationOrganizer
  around do |organizer|
    ActiveRecord::Base.transaction { organizer.call }
  end

  organize ValidatePlatformApplicationMode,
    CreateMarketApplication,
    SyncPlatformLots
end
