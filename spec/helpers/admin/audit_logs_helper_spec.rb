# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Admin::AuditLogsHelper, type: :helper do
  describe '#version_event_badge' do
    it 'renders a success badge for create events' do
      result = helper.version_event_badge('create')
      expect(result).to include('fr-badge--success')
      expect(result).to include('Création')
    end

    it 'renders an info badge for update events' do
      result = helper.version_event_badge('update')
      expect(result).to include('fr-badge--info')
      expect(result).to include('Modification')
    end

    it 'renders an error badge for destroy events' do
      result = helper.version_event_badge('destroy')
      expect(result).to include('fr-badge--error')
      expect(result).to include('Suppression')
    end
  end

  describe '#version_admin_user' do
    let(:admin_user) { create(:admin_user) }

    it 'returns the admin email when whodunnit is set' do
      version = instance_double(PaperTrail::Version, whodunnit: admin_user.id)
      expect(helper.version_admin_user(version)).to eq(admin_user.email)
    end

    it 'returns dash when whodunnit is blank' do
      version = instance_double(PaperTrail::Version, whodunnit: nil)
      expect(helper.version_admin_user(version)).to eq('-')
    end
  end

  describe '#version_scope_badge' do
    it 'returns buyer scope when only buyer attributes changed' do
      version = instance_double(PaperTrail::Version, changeset: { 'buyer_name' => %w[Old New] })
      expect(helper.version_scope_badge(version)).to eq('Acheteur')
    end

    it 'returns candidate scope when only candidate attributes changed' do
      version = instance_double(PaperTrail::Version, changeset: { 'candidate_name' => %w[Old New] })
      expect(helper.version_scope_badge(version)).to eq('Candidat')
    end

    it 'returns both scopes when buyer and candidate changed' do
      version = instance_double(PaperTrail::Version,
        changeset: { 'buyer_name' => %w[Old New], 'candidate_name' => %w[Old New] })
      expect(helper.version_scope_badge(version)).to eq('Acheteur / Candidat')
    end

    it 'ignores timestamp attributes when determining scope' do
      version = instance_double(PaperTrail::Version,
        changeset: { 'buyer_name' => %w[Old New], 'updated_at' => [nil, Time.current] })
      expect(helper.version_scope_badge(version)).to eq('Acheteur')
    end
  end

  describe '#version_changes' do
    it 'returns changeset from version' do
      changeset = { 'buyer_name' => %w[Old New] }
      version = instance_double(PaperTrail::Version, changeset:)
      expect(helper.version_changes(version)).to eq(changeset)
    end

    it 'returns empty hash when changeset is nil' do
      version = instance_double(PaperTrail::Version, changeset: nil)
      expect(helper.version_changes(version)).to eq({})
    end
  end

  describe '#categorized_changes' do
    it 'separates changes into buyer, candidate, and other groups' do
      changes = {
        'buyer_name' => [nil, 'Test'],
        'candidate_name' => [nil, 'Test'],
        'mandatory' => [nil, true],
        'updated_at' => [nil, Time.current],
        'id' => [nil, 1]
      }

      result = helper.categorized_changes(changes)

      expect(result[:buyer].keys).to eq(['buyer_name'])
      expect(result[:candidate].keys).to eq(['candidate_name'])
      expect(result[:other].keys).to eq(['mandatory'])
    end
  end

  describe '#format_change_value' do
    it 'formats nil as dash' do
      expect(helper.format_change_value(nil)).to eq('-')
    end

    it 'formats true as Oui' do
      expect(helper.format_change_value(true)).to eq('Oui')
    end

    it 'formats false as Non' do
      expect(helper.format_change_value(false)).to eq('Non')
    end

    it 'formats strings as-is' do
      expect(helper.format_change_value('hello')).to eq('hello')
    end
  end

  describe '#human_attribute_label' do
    it 'returns translated label for known attributes' do
      expect(helper.human_attribute_label('buyer_name')).to eq('Titre acheteur')
    end

    it 'returns humanized name for unknown attributes' do
      expect(helper.human_attribute_label('unknown_field')).to eq('Unknown field')
    end
  end
end
