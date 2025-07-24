# frozen_string_literal: true

class HomeController < ApplicationController
  def index; end

  def create_demo_market
    return redirect_to root_path, alert: t('demo.unavailable') unless demo_available?

    demo_editor = find_or_create_demo_editor
    public_market = create_random_market(demo_editor)

    redirect_to configure_buyer_public_market_path(public_market.identifier),
      notice: t('demo.market_created', market_name: public_market.market_name)
  rescue StandardError => e
    redirect_to root_path, alert: t('demo.creation_error', error: e.message)
  end

  private

  def demo_available?
    Rails.env.development? || Rails.env.sandbox?
  end

  def find_or_create_demo_editor
    Editor.find_or_create_by(client_id: 'demo_editor_client') do |editor|
      editor.name = 'Éditeur de Démonstration'
      editor.client_secret = 'demo_editor_secret'
      editor.authorized = true
      editor.active = true
    end
  end

  def create_random_market(editor)
    market_names = [
      'Fourniture de matériel informatique',
      'Services de nettoyage des locaux',
      'Travaux de rénovation énergétique',
      'Maintenance des espaces verts',
      'Prestations de restauration collective',
      'Fourniture de mobilier de bureau',
      'Services de sécurité et gardiennage'
    ]

    market_types = %w[supplies services works]

    editor.public_markets.create!(
      market_name: market_names.sample,
      lot_name: rand(1..3) == 1 ? "Lot #{rand(1..5)}" : nil,
      deadline: rand(30..180).days.from_now,
      market_type: market_types.sample
    )
  end
end
