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
if Rails.env.development?
  demo_editor = Editor.find_or_create_by(client_id: 'demo_editor_client') do |editor|
    editor.name = 'Demo Editor App'
    editor.client_secret = 'demo_editor_secret'
    editor.authorized = true
    editor.active = true
  end
  
  # Sync with Doorkeeper
  demo_editor.sync_to_doorkeeper!
  
  puts "✅ Demo editor created: #{demo_editor.name} (#{demo_editor.client_id})"
end
