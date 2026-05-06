# frozen_string_literal: true

Given('un éditeur avec une URL webhook exists') do
  @editor = create(:editor, :authorized_and_active,
    completion_webhook_url: 'https://editor.example.com/webhook')
end

Given('un marché public associé à cet éditeur exists') do
  @public_market = create(:public_market, editor: @editor, sync_status: :sync_pending,
    completed_at: Time.zone.now)
end

Given('le marché est en cours de synchronisation') do
  @public_market.update!(sync_status: :sync_processing)
end

Given('le marché a été synchronisé avec succès') do
  @public_market.update!(sync_status: :sync_completed)
end

Given('le marché a échoué à se synchroniser') do
  @public_market.update!(sync_status: :sync_failed)
end

Given('le webhook de l\'éditeur répond avec succès') do
  stub_request(:post, @editor.completion_webhook_url)
    .to_return(status: 200, body: 'OK')
end

When('je visite la page de statut de synchronisation acheteur') do
  visit buyer_sync_status_path(@public_market.identifier)
end

When('je clique sur {string}') do |label|
  click_on label
end

Then('je vois {string}') do |text|
  expect(page).to have_content(text)
end

Then('je vois l\'identifiant du marché sur la page') do
  expect(page).to have_content(@public_market.identifier)
end

Then('je vois un lien pour retourner sur l\'éditeur') do
  expect(page).to have_link(@editor.name)
end

Then('je vois un bouton {string}') do |label|
  expect(page).to have_button(label)
end

Then('je vois un lien {string}') do |label|
  expect(page).to have_link(label)
end
