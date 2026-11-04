# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Locale switcher links', type: :request do
  def locale_link_href(locale)
    Nokogiri::HTML(response.body).at_css("a.fr-translate__language[hreflang='#{locale}']")['href']
  end

  it 'keeps the current path and query parameters and sets the locale' do
    get root_path, params: { foo: 'bar' }

    expect(locale_link_href('en')).to eq('/?foo=bar&locale=en')
    expect(locale_link_href('fr')).to eq('/?foo=bar&locale=fr')
  end

  [
    { host: 'evil.example' },
    { protocol: 'https', host: 'evil.example' },
    { script_name: '//evil.example' },
    { port: '6666' },
    { anchor: 'injected' }
  ].each do |injected_params|
    it "does not let #{injected_params.keys.join(', ')} change the links" do
      get root_path, params: injected_params

      I18n.available_locales.map(&:to_s).each do |locale|
        href = locale_link_href(locale)
        expect(href).to start_with('/?')
        expect(URI.parse(href)).to have_attributes(scheme: nil, host: nil, path: '/', fragment: nil)
      end
    end
  end

  it 'does not let query parameters change the route of the links' do
    get root_path, params: { controller: 'home', action: 'command', command: 'set_city_timezone' }

    expect(response).to have_http_status(:ok)
    expect(URI.parse(locale_link_href('en')).path).to eq('/')
  end
end
