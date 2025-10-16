# frozen_string_literal: true

namespace :attestation do
  desc 'Generate attestation PDF (returns file path)'
  task :generate, [:identifier] => :environment do |_t, args|
    app = MarketApplication.find_by!(identifier: args[:identifier])
    app.attestation.purge if app.attestation.attached?
    GenerateAttestationPdf.call(market_application: app)
    puts Rails.root.join('storage', app.attestation.blob.key.split('/')[0..1].join('/'), app.attestation.blob.key)
  end

  desc 'Generate HTML preview (returns file path)'
  task :preview, [:identifier] => :environment do |_t, args|
    app = MarketApplication.includes(
      public_market: :market_attributes,
      market_attribute_responses: :market_attribute
    ).find_by!(identifier: args[:identifier])

    html = ApplicationController.render(
      template: 'candidate/attestations/show',
      formats: [:html],
      layout: false,
      locals: { market_application: app }
    )

    path = Rails.root.join('tmp', "attestation_#{args[:identifier]}.html")
    File.write(path, html)
    puts path
  end
end
