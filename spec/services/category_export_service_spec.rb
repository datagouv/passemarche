# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CategoryExportService do
  subject(:context) { described_class.call }

  before do
    cat_a = create(:category, key: 'cat_a', position: 0, buyer_label: 'Buyer A', candidate_label: 'Candidate A')
    cat_b = create(:category, key: 'cat_b', position: 1, buyer_label: 'Buyer B', candidate_label: 'Candidate B')
    create(:category, key: 'cat_deleted', position: 2, deleted_at: Time.current)

    create(:subcategory, category: cat_a, key: 'sub_a1', position: 0, buyer_label: 'Buyer A1', candidate_label: 'Candidate A1')
    create(:subcategory, category: cat_a, key: 'sub_a2', position: 1, buyer_label: 'Buyer A2', candidate_label: 'Candidate A2')
    create(:subcategory, category: cat_b, key: 'sub_b1', position: 0, buyer_label: 'Buyer B1', candidate_label: 'Candidate B1')
    create(:subcategory, category: cat_a, key: 'sub_deleted', position: 2, deleted_at: Time.current)
  end

  describe '#call' do
    it 'succeeds' do
      expect(context).to be_success
    end

    it 'exports active categories ordered by position' do
      keys = context.result['categories'].pluck('key')
      expect(keys).to eq(%w[cat_a cat_b])
    end

    it 'excludes soft-deleted categories' do
      keys = context.result['categories'].pluck('key')
      expect(keys).not_to include('cat_deleted')
    end

    it 'includes buyer and candidate labels' do
      cat_a = context.result['categories'].first
      expect(cat_a['buyer_label']).to eq('Buyer A')
      expect(cat_a['candidate_label']).to eq('Candidate A')
    end

    it 'exports subcategories nested under categories' do
      cat_a = context.result['categories'].first
      sub_keys = cat_a['subcategories'].pluck('key')
      expect(sub_keys).to eq(%w[sub_a1 sub_a2])
    end

    it 'excludes soft-deleted subcategories' do
      cat_a = context.result['categories'].first
      sub_keys = cat_a['subcategories'].pluck('key')
      expect(sub_keys).not_to include('sub_deleted')
    end

    it 'produces valid YAML output' do
      yaml_output = context.result.to_yaml
      parsed = YAML.safe_load(yaml_output)
      expect(parsed['categories'].size).to eq(2)
    end
  end
end
