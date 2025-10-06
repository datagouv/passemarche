# frozen_string_literal: true

require 'rails_helper'

# Test implementation of RepeatableField for specs
class TestRepeatableField < MarketAttributeResponse
  include MarketAttributeResponse::RepeatableField

  def self.item_schema
    {
      'name' => { type: 'string', required: true },
      'description' => { type: 'text', required: false },
      'count' => { type: 'integer', required: false }
    }
  end

  def self.json_schema_properties
    %w[items]
  end

  def self.json_schema_required
    []
  end

  def self.json_schema_error_field
    :value
  end
end

RSpec.describe MarketAttributeResponse::RepeatableField, type: :model do
  let(:market_application) { create(:market_application) }
  let(:market_attribute) { create(:market_attribute, input_type: :text_input) }

  subject(:response) do
    TestRepeatableField.new(
      market_application:,
      market_attribute:,
      value:
    )
  end

  describe 'inclusion' do
    let(:value) { {} }

    it 'includes FileAttachable concern' do
      expect(TestRepeatableField.included_modules).to include(MarketAttributeResponse::FileAttachable)
    end

    it 'includes JsonValidatable concern' do
      expect(TestRepeatableField.included_modules).to include(MarketAttributeResponse::JsonValidatable)
    end
  end

  describe '.item_schema' do
    it 'must be implemented by subclass' do
      expect(TestRepeatableField.item_schema).to be_a(Hash)
      expect(TestRepeatableField.item_schema.keys).to include('name', 'description', 'count')
    end

    it 'raises error if not implemented' do
      stub_class = Class.new(MarketAttributeResponse) do
        include MarketAttributeResponse::RepeatableField
      end

      expect { stub_class.item_schema }.to raise_error(NotImplementedError)
    end
  end

  describe '#items' do
    context 'when value is nil' do
      let(:value) { nil }

      it 'returns empty hash' do
        expect(response.items).to eq({})
      end
    end

    context 'when value has items' do
      let(:value) do
        {
          'items' => {
            '1738234567890' => { 'name' => 'Item 1', 'description' => 'First item' },
            '1738234567891' => { 'name' => 'Item 2', 'description' => 'Second item' }
          }
        }
      end

      it 'returns items hash' do
        expect(response.items).to eq({
          '1738234567890' => { 'name' => 'Item 1', 'description' => 'First item' },
          '1738234567891' => { 'name' => 'Item 2', 'description' => 'Second item' }
        })
      end
    end

    context 'when value exists but no items' do
      let(:value) { { 'other_key' => 'data' } }

      it 'returns empty hash' do
        expect(response.items).to eq({})
      end
    end
  end

  describe '#items=' do
    let(:value) { nil }

    it 'sets items hash in value' do
      response.items = { '1738234567890' => { 'name' => 'Test' } }
      expect(response.value).to eq({ 'items' => { '1738234567890' => { 'name' => 'Test' } } })
    end

    it 'handles non-hash input by creating empty hash' do
      response.items = 'not a hash'
      expect(response.value).to eq({ 'items' => {} })
    end

    it 'marks value as will change' do
      initial_value = response.value
      response.items = { '1738234567890' => { 'name' => 'New' } }
      expect(response.value).not_to eq(initial_value)
      expect(response.value).to eq({ 'items' => { '1738234567890' => { 'name' => 'New' } } })
    end
  end

  describe '#get_item_field' do
    context 'when item exists' do
      let(:value) do
        {
          'items' => {
            '1738234567890' => { 'name' => 'First', 'description' => 'Desc 1' },
            '1738234567891' => { 'name' => 'Second', 'description' => 'Desc 2' }
          }
        }
      end

      it 'returns field value for existing item' do
        expect(response.get_item_field('1738234567890', 'name')).to eq('First')
        expect(response.get_item_field('1738234567891', 'description')).to eq('Desc 2')
      end

      it 'returns nil for non-existent field' do
        expect(response.get_item_field('1738234567890', 'nonexistent')).to be_nil
      end
    end

    context 'when item does not exist' do
      let(:value) { { 'items' => { '1738234567890' => { 'name' => 'First' } } } }

      it 'returns nil' do
        expect(response.get_item_field('9999999999999', 'name')).to be_nil
      end
    end

    context 'when items is empty' do
      let(:value) { {} }

      it 'returns nil' do
        expect(response.get_item_field('1738234567890', 'name')).to be_nil
      end
    end
  end

  describe '#set_item_field' do
    let(:value) { nil }

    it 'creates item and sets field value' do
      response.set_item_field('1738234567890', 'name', 'Test Item')
      expect(response.items['1738234567890']['name']).to eq('Test Item')
    end

    it 'initializes value hash when blank' do
      expect(response.value).to be_nil
      response.set_item_field('1738234567890', 'name', 'Test')
      expect(response.value).to be_a(Hash)
      expect(response.value['items']).to be_a(Hash)
    end

    it 'creates items with any timestamp without gaps' do
      response.set_item_field('1738234567893', 'name', 'Item at timestamp 93')
      expect(response.items.length).to eq(1)
      expect(response.items['1738234567893']).to eq({ 'name' => 'Item at timestamp 93' })
    end

    it 'converts blank values to nil (presence check)' do
      response.set_item_field('1738234567890', 'name', '')
      expect(response.items['1738234567890']['name']).to be_nil
    end

    it 'updates value correctly' do
      initial_value = response.value
      response.set_item_field('1738234567890', 'name', 'Changed')
      expect(response.value).not_to eq(initial_value)
      expect(response.items['1738234567890']['name']).to eq('Changed')
    end
  end

  describe '#assign_attributes processing' do
    let(:value) { nil }
    let(:timestamp1) { '1738234567890' }
    let(:timestamp2) { '1738234567891' }
    let(:timestamp3) { '1738234567892' }

    describe 'reading via get_item_field' do
      it 'returns nil when item does not exist' do
        expect(response.get_item_field(timestamp1, 'name')).to be_nil
      end

      it 'returns field value when item exists' do
        response.value = { 'items' => { timestamp1 => { 'name' => 'Test' } } }
        expect(response.get_item_field(timestamp1, 'name')).to eq('Test')
      end
    end

    describe 'writing via assign_attributes' do
      it 'creates item and sets field' do
        response.assign_attributes("item_#{timestamp1}_name" => 'New Name')
        expect(response.items[timestamp1]['name']).to eq('New Name')
      end

      it 'updates existing item field' do
        response.value = { 'items' => { timestamp1 => { 'name' => 'Old', 'description' => 'Desc' } } }
        response.assign_attributes("item_#{timestamp1}_name" => 'Updated')
        expect(response.items[timestamp1]['name']).to eq('Updated')
        expect(response.items[timestamp1]['description']).to eq('Desc') # Other fields unchanged
      end

      it 'handles multiple items in one call' do
        response.assign_attributes(
          "item_#{timestamp1}_name" => 'First',
          "item_#{timestamp2}_name" => 'Second',
          "item_#{timestamp3}_name" => 'Third'
        )

        expect(response.items.length).to eq(3)
        expect(response.items[timestamp1]['name']).to eq('First')
        expect(response.items[timestamp2]['name']).to eq('Second')
        expect(response.items[timestamp3]['name']).to eq('Third')
      end

      it 'handles setting different fields on same item' do
        response.assign_attributes(
          "item_#{timestamp1}_name" => 'Item Name',
          "item_#{timestamp1}_description" => 'Item Description',
          "item_#{timestamp1}_count" => '5'
        )

        expect(response.items[timestamp1]).to eq({
          'name' => 'Item Name',
          'description' => 'Item Description',
          'count' => '5'
        })
      end

      it 'handles _destroy flag' do
        response.assign_attributes(
          "item_#{timestamp1}_name" => 'First',
          "item_#{timestamp2}_name" => 'Second'
        )
        expect(response.items.keys).to match_array([timestamp1, timestamp2])

        response.assign_attributes("item_#{timestamp1}__destroy" => '1')
        expect(response.items.keys).to eq([timestamp2])
      end
    end
  end

  describe 'integration with JsonValidatable' do
    let(:value) { { 'items' => { '1738234567890' => { 'name' => 'Test' } } } }

    it 'includes JsonValidatable concern' do
      # JsonValidatable is included
      expect(TestRepeatableField.included_modules).to include(MarketAttributeResponse::JsonValidatable)
    end

    it 'validates extra properties if json_schema_properties defined' do
      response.value = { 'items' => {}, 'extra_key' => 'not allowed' }
      response.valid?
      expect(response.errors[:value]).to include(I18n.t('activerecord.errors.json_schema.additional_properties'))
    end
  end

  describe 'value structure' do
    let(:value) { nil }
    let(:timestamp1) { '1738234567890' }
    let(:timestamp2) { '1738234567891' }
    let(:timestamp3) { '1738234567892' }

    it 'stores items in correct JSON structure with timestamps' do
      response.assign_attributes(
        "item_#{timestamp1}_name" => 'Item Name',
        "item_#{timestamp1}_description" => 'Item Description'
      )

      expect(response.value).to eq({
        'items' => {
          timestamp1 => { 'name' => 'Item Name', 'description' => 'Item Description' }
        }
      })
    end

    it 'maintains structure across multiple items' do
      response.assign_attributes(
        "item_#{timestamp1}_name" => 'First',
        "item_#{timestamp2}_name" => 'Second',
        "item_#{timestamp3}_name" => 'Third'
      )

      expect(response.value['items'].length).to eq(3)
      expect(response.value['items'].values.pluck('name')).to match_array(%w[First Second Third])
    end
  end
end
