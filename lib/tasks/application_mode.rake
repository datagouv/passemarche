# frozen_string_literal: true

namespace :application_mode do
  desc 'Set application_mode: solo on candidacies created before the Groupement module (application_mode: nil)'
  task backfill_solo: :environment do
    scope = MarketApplication.where(application_mode: nil)
    count = scope.count

    if count.zero?
      puts 'No candidacy with application_mode: nil, nothing to do.'
      next
    end

    scope.update_all(application_mode: MarketApplication.application_modes.fetch(:solo)) # rubocop:disable Rails/SkipsModelValidations
    puts "#{count} candidacy(ies) updated to application_mode: solo."
  end
end
