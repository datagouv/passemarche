# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CategoryDataMigrationService do
  let(:service) { described_class.new }

  let(:translations) do
    {
      'fr' => {
        'form_fields' => {
          'buyer' => {
            'categories' => {
              'cat_a' => 'Buyer Cat A',
              'cat_b' => 'Buyer Cat B'
            },
            'subcategories' => {
              'sub_a1' => 'Buyer Sub A1',
              'sub_b1' => 'Buyer Sub B1'
            }
          },
          'candidate' => {
            'categories' => {
              'cat_a' => 'Candidate Cat A',
              'cat_b' => 'Candidate Cat B'
            },
            'subcategories' => {
              'sub_a1' => 'Candidate Sub A1',
              'sub_b1' => 'Candidate Sub B1'
            }
          }
        }
      }
    }
  end

  before do
    allow(YAML).to receive(:load_file)
      .with(CategoryDataMigrationService::TRANSLATION_FILE)
      .and_return(translations)

    create(:market_attribute, category_key: 'cat_a', subcategory_key: 'sub_a1', key: 'field_1')
    create(:market_attribute, category_key: 'cat_a', subcategory_key: 'sub_a1', key: 'field_2')
    create(:market_attribute, category_key: 'cat_b', subcategory_key: 'sub_b1', key: 'field_3')
  end

  describe '#perform' do
    it 'succeeds' do
      service.perform
      expect(service).to be_success
    end

    it 'creates categories from unique category_keys' do
      expect { service.perform }.to change(Category, :count).by(2)
    end

    it 'creates subcategories from unique [category_key, subcategory_key] pairs' do
      expect { service.perform }.to change(Subcategory, :count).by(2)
    end

    it 'assigns buyer and candidate labels to categories' do
      service.perform
      cat_a = Category.find_by(key: 'cat_a')
      expect(cat_a.buyer_label).to eq('Buyer Cat A')
      expect(cat_a.candidate_label).to eq('Candidate Cat A')
    end

    it 'assigns buyer and candidate labels to subcategories' do
      service.perform
      sub_a1 = Subcategory.find_by(key: 'sub_a1')
      expect(sub_a1.buyer_label).to eq('Buyer Sub A1')
      expect(sub_a1.candidate_label).to eq('Candidate Sub A1')
    end

    it 'backfills subcategory_id on market_attributes' do
      service.perform
      sub_a1 = Subcategory.find_by(key: 'sub_a1')

      expect(MarketAttribute.where(subcategory_key: 'sub_a1').pluck(:subcategory_id).uniq)
        .to eq([sub_a1.id])
    end

    it 'returns migration statistics' do
      service.perform
      expect(service.result).to eq(
        categories_created: 2,
        subcategories_created: 2,
        attributes_linked: 3
      )
    end

    context 'when run twice (idempotent)' do
      before { service.perform }

      it 'does not duplicate categories' do
        expect { described_class.new.tap(&:perform) }.not_to change(Category, :count)
      end

      it 'does not duplicate subcategories' do
        expect { described_class.new.tap(&:perform) }.not_to change(Subcategory, :count)
      end
    end
  end
end
