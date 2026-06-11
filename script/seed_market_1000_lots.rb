# frozen_string_literal: true

#
# Usage: bin/rails runner script/seed_market_1000_lots.rb
#
# Creates a test market with 1000 lots on sandbox/dev/staging.
# The product team can use this to stress-test the lot selection UI.

unless Rails.env.development? || Rails.env.sandbox? || Rails.env.staging?
  puts '❌ Only available in development, sandbox or staging.'
  exit 1
end

LOT_TYPES = [
  { type: 'supplies', names: ["Fourniture d'ordinateurs", 'Fourniture de véhicules légers', 'Fourniture de vêtements professionnels', 'Fourniture de mobilier de bureau', "Fourniture de matériels d'impression"], cpv_codes: %w[30213000-5 34110000-1 18110000-3 39130000-2 30232100-5] },
  { type: 'services',  names: ['Services de nettoyage des locaux', 'Services de gardiennage', 'Services de formation professionnelle', 'Services de restauration collective', 'Services de maintenance informatique'], cpv_codes: %w[90910000-9 79710000-4 80530000-8 55520000-1 72500000-0] },
  { type: 'works',     names: ['Travaux de couverture et étanchéité', 'Travaux de ravalement de façades', "Travaux d'électricité", 'Travaux de plomberie et chauffage', 'Travaux de menuiserie'], cpv_codes: %w[45261000-4 45443000-4 45311000-0 45330000-9 45420000-7] }
].freeze

LOCATIONS = ['Bâtiment A', 'Bâtiment B', 'Zone 1', 'Zone 2', 'Parc des expositions', 'Centre technique', 'Site principal', 'Annexe Nord', 'Annexe Sud'].freeze

lots_data = Array.new(1000) do |i|
  type_def   = LOT_TYPES[i % LOT_TYPES.size]
  name_base  = type_def[:names][i % type_def[:names].size]
  location   = LOCATIONS[i % LOCATIONS.size]
  cpv_code   = type_def[:cpv_codes][i % type_def[:cpv_codes].size]

  { name: "Lot #{i + 1} - #{name_base} - #{location}", type: type_def[:type], cpv_code: }
end

puts "📋 #{lots_data.size} lots generated"

editor = Editor.find_by!(client_id: 'demo_editor_client')

market = PublicMarket.new(
  editor:,
  name: '[TEST] Marché 1000 lots',
  deadline: 6.months.from_now,
  siret: '13002526500013',
  market_type_codes: %w[supplies],
  buyer_name: 'Direction des Achats'
)
market.save!
puts "✅ Market: #{market.name} (#{market.identifier})"

market_types = MarketType.all.index_by(&:code)
now = Time.current

Lot.insert_all!( # rubocop:disable Rails/SkipsModelValidations
  lots_data.map.with_index(1) do |lot, position|
    {
      public_market_id: market.id,
      name: lot[:name],
      cpv_code: lot[:cpv_code],
      platform_market_type_id: market_types[lot[:type]]&.id,
      position:,
      created_at: now,
      updated_at: now
    }
  end
)

puts "✅ #{market.lots.count} lots created"

fake_editor_db = Rails.root.join('fake_editor_app/fake_editor.db')
if File.exist?(fake_editor_db)
  sql = "INSERT OR REPLACE INTO markets (identifier, name, status, created_at) VALUES ('#{market.identifier}', '#{market.name.gsub("'", "''")}', 'created', datetime('now'));"
  system("sqlite3 #{fake_editor_db} \"#{sql}\"")
  puts '✅ Market registered in fake editor DB'
else
  puts '⚠️  Fake editor DB not found — add the market manually in the fake editor'
end

puts ''
puts "🎯 Identifier : #{market.identifier}"
