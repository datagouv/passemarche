require 'rails_helper'

RSpec.describe 'Application layout stylesheets', type: :request do
  it 'loads each local stylesheet from app/assets exactly once, via a single stylesheet_link_tag :app' do
    get candidate_home_path

    local_stylesheet_hrefs = response.body.scan(%r{href="(/assets/[^"]+\.css[^"]*)"}).flatten

    expect(local_stylesheet_hrefs).not_to be_empty
    expect(local_stylesheet_hrefs.uniq.length).to eq(local_stylesheet_hrefs.length)
  end

  it 'does not declare a second stylesheet_link_tag through content_for(:head)' do
    get candidate_home_path

    local_stylesheet_tags = response.body.scan(%r{<link[^>]*href="/assets/[^"]+\.css[^"]*"[^>]*>})

    expect(local_stylesheet_tags.length).to eq(Rails.root.glob('app/assets/**/*.css').length)
  end
end
