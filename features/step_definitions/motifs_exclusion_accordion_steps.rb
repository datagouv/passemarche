# frozen_string_literal: true

Then('I should see a link {string}') do |text|
  expect(page).to have_link(text)
end

Then('the article link {string} should open in a new tab') do |text|
  link = find(:link, text)
  expect(link[:target]).to eq('_blank')
  expect(link[:rel]).to include('noopener')
end

Then('the motifs exclusion accordion should be closed') do
  button = find('button[aria-controls="motifs-exclusion-details"]')
  expect(button[:'aria-expanded']).to eq('false')
end

Then('the motifs exclusion accordion details should not be visible') do
  expect(page).not_to have_css('#motifs-exclusion-details.fr-collapse--expanded')
end

Then('the accordion content should include {string}') do |text|
  expect(page).to have_css('#motifs-exclusion-details', text:, visible: :all)
end

Then('the accordion content should have a tag {string}') do |text|
  expect(page).to have_css('#motifs-exclusion-details span.fr-tag', text:, visible: :all)
end

Then('the condemnation tags should not be links') do
  page.all('#motifs-exclusion-details span.fr-tag', visible: :all).each do |tag|
    expect(tag.tag_name).to eq('span')
  end
end
