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
if Rails.env.development? || Rails.env.sandbox?
  # Set base URL based on environment
  base_url = Rails.env.sandbox? ? 'https://sandbox.voie-rapide-edition.services.api.gouv.fr' : 'http://localhost:4567'
  
  demo_editor = Editor.find_or_create_by(client_id: 'demo_editor_client') do |editor|
    editor.name = 'Demo Editor App'
    editor.client_secret = 'demo_editor_secret'
    editor.authorized = true
    editor.active = true
    editor.completion_webhook_url = "#{base_url}/webhooks/voie-rapide"
    editor.redirect_url = "#{base_url}/"
  end

  # Generate webhook secret if not present
  if demo_editor.webhook_secret.blank?
    demo_editor.generate_webhook_secret!
    demo_editor.save!
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

# Create MarketAttribute records from YAML data
puts "\n📝 Creating MarketAttribute records..."

# Load YAML data with aliases enabled
field_types_config = YAML.load_file(Rails.root.join('config/form_fields/field_types.yml'), aliases: true)
field_requirements_config = YAML.load_file(Rails.root.join('config/form_fields/field_requirements.yml'), aliases: true)

# Get field types for current environment
field_types = field_types_config[Rails.env] || field_types_config['default']
field_requirements = field_requirements_config[Rails.env] || field_requirements_config['default']

# Create MarketAttribute records
field_types.each do |field_key, field_config|
  market_attribute = MarketAttribute.find_or_create_by(key: field_key) do |attr|
    # Map YAML field type to database input_type (using symbols for enum)
    attr.input_type = case field_config['type']
                      when 'document_upload' then :file_upload
                      when 'text_field' then :text_input
                      when 'checkbox_field' then :checkbox
                      else :text_input
                      end

    attr.category_key = field_config['category']
    attr.subcategory_key = field_config['subcategory']
    attr.from_api = field_config['source_type'] == 'authentic_source'
    attr.required = false # Will be set based on market type relationships
  end
  puts "✅ MarketAttribute created: #{market_attribute.key} (#{market_attribute.category_key})"
end

# Create relationships between MarketTypes and MarketAttributes
puts "\n🔗 Creating MarketType-MarketAttribute relationships..."

# Process each market type's requirements
field_requirements['market_types']&.each do |market_type_code, requirements|
  market_type = MarketType.find_by(code: market_type_code)
  next unless market_type

  puts "  Processing #{market_type_code}..."

  # Required fields - mark them as required
  requirements['required']&.each do |field_key|
    market_attribute = MarketAttribute.find_by(key: field_key)
    next unless market_attribute

    # Mark as required and add to market type
    market_attribute.update!(required: true)
    unless market_type.market_attributes.include?(market_attribute)
      market_type.market_attributes << market_attribute
      puts "    ✅ Required: #{field_key}"
    end
  end

  # Optional fields - keep them as not required
  requirements['optional']&.each do |field_key|
    market_attribute = MarketAttribute.find_by(key: field_key)
    next unless market_attribute

    # Create join record if not exists
    unless market_type.market_attributes.include?(market_attribute)
      market_type.market_attributes << market_attribute
      puts "    ✅ Optional: #{field_key}"
    end
  end
end

# Process defense-specific requirements
defense_requirements = field_requirements['defense']
defense_market_type = MarketType.find_by(code: 'defense')

if defense_market_type && defense_requirements
  puts '  Processing defense requirements...'

  # Required defense fields - mark as required
  defense_requirements['required']&.each do |field_key|
    market_attribute = MarketAttribute.find_by(key: field_key)
    next unless market_attribute

    # Mark as required and add to defense market type
    market_attribute.update!(required: true)
    unless defense_market_type.market_attributes.include?(market_attribute)
      defense_market_type.market_attributes << market_attribute
      puts "    ✅ Defense Required: #{field_key}"
    end
  end

  # Optional defense fields - keep as not required
  defense_requirements['optional']&.each do |field_key|
    market_attribute = MarketAttribute.find_by(key: field_key)
    next unless market_attribute

    unless defense_market_type.market_attributes.include?(market_attribute)
      defense_market_type.market_attributes << market_attribute
      puts "    ✅ Defense Optional: #{field_key}"
    end
  end
end

puts "\n🎉 Seed data creation completed successfully!"
puts '📊 Summary:'
puts "   - MarketTypes: #{MarketType.count}"
puts "   - MarketAttributes: #{MarketAttribute.count}"
puts "   - Total relationships: #{MarketType.joins(:market_attributes).count}"
