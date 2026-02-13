# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end

# Create demo editor for fake_editor_app in development
if Rails.env.development? || Rails.env.sandbox? || Rails.env.staging?
  # Set base URL based on environment
  base_url = Rails.env.development? ? 'http://localhost:4567' : "https://#{Rails.env}.editeur.passemarche.data.gouv.fr"

  demo_editor = Editor.find_or_create_by(client_id: 'demo_editor_client') do |editor|
    editor.name = 'Demo Editor App'
    editor.client_secret = 'demo_editor_secret'
    editor.authorized = true
    editor.active = true
    editor.completion_webhook_url = "#{base_url}/webhooks/voie-rapide"
    editor.redirect_url = "#{base_url}/"
    editor.can_create_defense_markets = true
  end

  demo_editor.update!(can_create_defense_markets: true) unless demo_editor.can_create_defense_markets?

  # Generate webhook secret if not present
  if demo_editor.webhook_secret.blank?
    demo_editor.generate_webhook_secret!
    puts '   🔐 Generated webhook secret for demo editor'
  end

  # Sync with Doorkeeper
  demo_editor.sync_to_doorkeeper!

  puts "✅ Demo editor created: #{demo_editor.name} (#{demo_editor.client_id})"
  puts "   📡 Webhook URL: #{demo_editor.completion_webhook_url}"
  puts "   ↩️  Redirect URL: #{demo_editor.redirect_url}"
end

# Create admin account for all environments
admin_user = AdminUser.find_or_create_by(email: 'admin@voie-rapide.gouv.fr') do |admin|
  admin.password = 'password123'
  admin.password_confirmation = 'password123'
end

puts "✅ Admin user created: #{admin_user.email}"

# Create MarketType records
puts "\n🏗️  Creating MarketType records..."

market_types_data = [
  { code: 'supplies' },
  { code: 'services' },
  { code: 'works' },
  { code: 'defense' }
]

market_types_data.each do |data|
  market_type = MarketType.find_or_create_by(code: data[:code])
  puts "✅ MarketType created: #{market_type.code}"
end

# Import field configuration from CSV
puts "\n📝 Importing field configuration from CSV..."

begin
  result = FieldConfigurationImport.call(csv_file_path: Rails.root.join('config/form_fields/fields.csv'))

  if result.success?
    puts '✅ Field configuration imported successfully!'
    stats = result.statistics
    puts "   • #{stats[:created]} created, #{stats[:updated]} updated, #{stats[:skipped]} skipped"
  else
    puts "❌ Field configuration import failed: #{result.message}"
    puts "   You can run 'bin/rails field_configuration:import' manually to retry"
  end
rescue StandardError => e
  puts "❌ Field configuration import failed: #{e.message}"
  puts "   You can run 'bin/rails field_configuration:import' manually to retry"
end

puts "\n🎉 Seed data creation completed successfully!"
puts '📊 Summary:'
puts "   - MarketTypes: #{MarketType.count}"
puts "   - MarketAttributes: #{MarketAttribute.count}"
puts "   - Total relationships: #{MarketType.joins(:market_attributes).count}"
