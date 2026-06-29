# frozen_string_literal: true

#
# Usage: ruby script/seed_market_1000_lots.rb [FAKE_EDITOR_URL]
#
# Creates a test market with 1000 lots by posting to the fake editor,
# which then calls the Rails API and stores the market in its own DB.
# The market will be visible in the fake editor dashboard immediately.
#
# The script authenticates automatically if needed.
#
# Examples:
#   ruby script/seed_market_1000_lots.rb                           # default: http://localhost:4567
#   ruby script/seed_market_1000_lots.rb https://editor.sandbox.example.com

require 'net/http'
require 'uri'

FAKE_EDITOR_URL = (ARGV[0] || ENV['FAKE_EDITOR_URL'] || 'http://localhost:4567').chomp('/')

LOT_TYPES = [
  { type: 'supplies', names: ["Fourniture d'ordinateurs", 'Fourniture de vehicules legers', 'Fourniture de vetements professionnels', 'Fourniture de mobilier de bureau', "Fourniture de materiels d'impression"], cpv_codes: %w[30213000-5 34110000-1 18110000-3 39130000-2 30232100-5] },
  { type: 'services', names: ['Services de nettoyage des locaux', 'Services de gardiennage', 'Services de formation professionnelle', 'Services de restauration collective', 'Services de maintenance informatique'], cpv_codes: %w[90910000-9 79710000-4 80530000-8 55520000-1 72500000-0] },
  { type: 'works', names: ['Travaux de couverture et etancheite', 'Travaux de ravalement de facades', "Travaux d'electricite", 'Travaux de plomberie et chauffage', 'Travaux de menuiserie'], cpv_codes: %w[45261000-4 45443000-4 45311000-0 45330000-9 45420000-7] }
].freeze

LOCATIONS = %w[BatimentA BatimentB Zone1 Zone2 Parc Centre SitePrincipal AnnexeNord AnnexeSud].freeze

def http_client(url)
  uri = URI(url)
  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = uri.scheme == 'https'
  http.read_timeout = 120
  http.open_timeout = 10
  [http, uri]
end

def authenticate!
  puts '🔑 Authenticating fake editor...'
  http, uri = http_client("#{FAKE_EDITOR_URL}/authenticate")
  request = Net::HTTP::Post.new(uri.path)
  request['Content-Type'] = 'application/x-www-form-urlencoded'
  response = http.request(request)

  case response
  when Net::HTTPRedirection
    puts '✅ Authenticated'
  else
    abort "❌ Authentication failed: HTTP #{response.code}"
  end
end

lots = Array.new(1000) do |i|
  type_def = LOT_TYPES[i % LOT_TYPES.size]
  name_base = type_def[:names][i % type_def[:names].size]
  location = LOCATIONS[i % LOCATIONS.size]
  cpv_code = type_def[:cpv_codes][i % type_def[:cpv_codes].size]
  { name: "#{name_base} - #{location}", cpv_code: }
end

puts "📋 #{lots.size} lots generated"

authenticate!

deadline = (Time.zone.now + (6 * 30 * 24 * 3600)).strftime('%Y-%m-%dT%H:%M')

body = URI.encode_www_form(
  [
    ['name', '[TEST] Marche 1000 lots'],
    ['deadline', deadline],
    %w[siret 13002526500013],
    ['market_type_codes[]', 'supplies'],
    *lots.flat_map { |lot| [['lots[][name]', lot[:name]], ['lots[][cpv_code]', lot[:cpv_code]]] }
  ]
)

http, uri = http_client("#{FAKE_EDITOR_URL}/buyer/markets")
puts "🚀 POST #{uri} (#{body.bytesize} bytes)..."

request = Net::HTTP::Post.new(uri.path)
request['Content-Type'] = 'application/x-www-form-urlencoded'
request.body = body
response = http.request(request)

case response
when Net::HTTPRedirection
  puts "✅ Market created! Redirect: #{response['Location']}"
when Net::HTTPSuccess
  if response.body.include?('fr-alert--error')
    error = response.body[%r{fr-alert--error.*?</p>}m]&.gsub(/<[^>]+>/, '')&.strip
    abort "❌ Error: #{error}"
  elsif response.body.include?('market_created') || response.body.include?('avec succ')
    puts '✅ Market created!'
  else
    abort '❌ Unexpected response (HTTP 200 but no success marker). Check fake editor logs.'
  end
else
  abort "❌ Failed: HTTP #{response.code}\n#{response.body&.slice(0, 500)}"
end
