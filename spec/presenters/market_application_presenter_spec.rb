# frozen_string_literal: true

require 'rails_helper'

RSpec.describe MarketApplicationPresenter, type: :presenter do
  let(:editor) { create(:editor) }
  let(:public_market) { create(:public_market, :completed, editor:) }
  let(:market_application) { create(:market_application, public_market:) }

  let!(:identity_attr) do
    create(:market_attribute,
      key: 'company_name',
      category_key: 'identite_entreprise',
      subcategory_key: 'identification',
      public_markets: [public_market])
  end

  let!(:exclusion_attr) do
    create(:market_attribute,
      key: 'exclusion_question',
      category_key: 'exclusion_criteria',
      subcategory_key: 'exclusion_criteria',
      public_markets: [public_market])
  end

  let!(:economic_attr) do
    create(:market_attribute,
      key: 'turnover',
      category_key: 'economic_capacities',
      subcategory_key: 'financial_capacity',
      public_markets: [public_market])
  end

  subject(:presenter) { described_class.new(market_application) }

  describe '#stepper_steps' do
    it 'returns categories plus summary as symbols' do
      expected_steps = %i[identite_entreprise exclusion_criteria economic_capacities summary]
      expect(presenter.stepper_steps).to match_array(expected_steps)
    end

    it 'includes summary as the last step' do
      expect(presenter.stepper_steps.last).to eq(:summary)
    end

    context 'with no market attributes' do
      let(:empty_market) { create(:public_market, :completed, editor:) }
      let(:empty_application) { create(:market_application, public_market: empty_market) }
      let(:empty_presenter) { described_class.new(empty_application) }

      it 'returns only summary' do
        expect(empty_presenter.stepper_steps).to eq([:summary])
      end
    end
  end

  describe '#wizard_steps' do
    it 'returns fixed steps, subcategories, and summary' do
      expected_steps = %i[
        company_identification
        api_data_recovery_status
        market_information
        identification
        exclusion_criteria
        financial_capacity
        summary
      ]
      expect(presenter.wizard_steps).to match_array(expected_steps)
    end

    it 'removes duplicates with uniq' do
      create(:market_attribute,
        key: 'another_field',
        category_key: 'identite_entreprise',
        subcategory_key: 'identification',
        public_markets: [public_market])

      identification_count = presenter.wizard_steps.count(:identification)
      expect(identification_count).to eq(1)
    end
  end

  describe '#parent_category_for' do
    it 'returns correct parent category for a subcategory' do
      expect(presenter.parent_category_for('identification')).to eq('identite_entreprise')
      expect(presenter.parent_category_for('exclusion_criteria')).to eq('exclusion_criteria')
      expect(presenter.parent_category_for('financial_capacity')).to eq('economic_capacities')
    end

    it 'handles symbol input' do
      expect(presenter.parent_category_for(:identification)).to eq('identite_entreprise')
    end

    it 'returns special case for market_information' do
      expect(presenter.parent_category_for('market_information')).to eq('identite_entreprise')
      expect(presenter.parent_category_for(:market_information)).to eq('identite_entreprise')
    end

    it 'returns nil for unknown subcategory' do
      expect(presenter.parent_category_for('unknown_subcategory')).to be_nil
    end

    it 'returns nil for blank input' do
      expect(presenter.parent_category_for('')).to be_nil
      expect(presenter.parent_category_for(nil)).to be_nil
    end
  end

  describe '#display_sidemenu?' do
    it 'returns true when there are multiple subcategories' do
      subcategories = { 'sub1' => [], 'sub2' => [] }
      expect(presenter.display_sidemenu?(subcategories)).to be true
    end

    it 'returns false when there is only one subcategory' do
      subcategories = { 'sub1' => [] }
      expect(presenter.display_sidemenu?(subcategories)).to be false
    end
  end

  describe '#subcategories_for_category' do
    it 'returns subcategories for a given category' do
      subcategories = presenter.subcategories_for_category('identite_entreprise')
      expect(subcategories).to include('market_information', 'identification')
    end

    it 'includes market_information first for identite_entreprise' do
      subcategories = presenter.subcategories_for_category('identite_entreprise')
      expect(subcategories.first).to eq('market_information')
    end

    it 'returns subcategories for other categories' do
      subcategories = presenter.subcategories_for_category('economic_capacities')
      expect(subcategories).to eq(['financial_capacity'])
    end

    it 'returns empty array for unknown category' do
      expect(presenter.subcategories_for_category('unknown_category')).to eq([])
    end

    it 'returns empty array for blank input' do
      expect(presenter.subcategories_for_category('')).to eq([])
      expect(presenter.subcategories_for_category(nil)).to eq([])
    end

    it 'orders subcategories consistently by ID order' do
      # Create attributes and test that ordering is consistent with ID order
      attr_z = create(:market_attribute,
        key: 'field_z',
        category_key: 'test_category',
        subcategory_key: 'z_subcategory',
        public_markets: [public_market])

      attr_a = create(:market_attribute,
        key: 'field_a',
        category_key: 'test_category',
        subcategory_key: 'a_subcategory',
        public_markets: [public_market])

      # Test that the order matches the ID order
      subcategories = presenter.subcategories_for_category('test_category')
      expected_order = [attr_z, attr_a].sort_by(&:id).map(&:subcategory_key)
      expect(subcategories).to eq(expected_order)
    end
  end

  describe 'constants' do
    it 'has correct initial wizard steps' do
      expect(described_class::INITIAL_WIZARD_STEPS).to eq(%i[company_identification api_data_recovery_status market_information])
    end

    it 'has correct final wizard step' do
      expect(described_class::FINAL_WIZARD_STEP).to eq(:summary)
    end

    it 'has correct market info parent category' do
      expect(described_class::MARKET_INFO_PARENT_CATEGORY).to eq('identite_entreprise')
    end
  end

  describe '#all_market_attributes ordering' do
    let(:ordered_market) { create(:public_market, :completed, editor:) }
    let(:ordered_application) { create(:market_application, public_market: ordered_market) }
    let(:ordered_presenter) { described_class.new(ordered_application) }

    it 'returns attributes sorted by position' do
      attr_last = create(:market_attribute, key: 'last', position: 3,
        category_key: 'cat', subcategory_key: 'sub', public_markets: [ordered_market])
      attr_first = create(:market_attribute, key: 'first', position: 1,
        category_key: 'cat', subcategory_key: 'sub', public_markets: [ordered_market])
      attr_middle = create(:market_attribute, key: 'middle', position: 2,
        category_key: 'cat', subcategory_key: 'sub', public_markets: [ordered_market])

      attributes = ordered_presenter.send(:all_market_attributes)

      expect(attributes).to eq([attr_first, attr_middle, attr_last])
    end
  end

  describe '#optional_market_attributes?' do
    context 'when there are optional market attributes' do
      before do
        create(:market_attribute,
          key: 'optional_field',
          mandatory: false,
          category_key: 'identite_entreprise',
          subcategory_key: 'identification',
          public_markets: [public_market])
      end

      it 'returns true' do
        expect(presenter.optional_market_attributes?).to be true
      end
    end

    context 'when all market attributes are mandatory' do
      let(:mandatory_market) { create(:public_market, :completed, editor:) }
      let(:mandatory_application) { create(:market_application, public_market: mandatory_market) }
      let(:mandatory_presenter) { described_class.new(mandatory_application) }

      before do
        create(:market_attribute,
          key: 'mandatory_field',
          mandatory: true,
          category_key: 'identite_entreprise',
          subcategory_key: 'identification',
          public_markets: [mandatory_market])
      end

      it 'returns false' do
        expect(mandatory_presenter.optional_market_attributes?).to be false
      end
    end

    context 'when there are no market attributes' do
      let(:empty_market) { create(:public_market, :completed, editor:) }
      let(:empty_application) { create(:market_application, public_market: empty_market) }
      let(:empty_presenter) { described_class.new(empty_application) }

      it 'returns false' do
        expect(empty_presenter.optional_market_attributes?).to be false
      end
    end
  end

  describe '#missing_mandatory_motifs_exclusion?' do
    let(:motifs_market) { create(:public_market, :completed, editor:) }
    let(:motifs_application) { create(:market_application, public_market: motifs_market) }
    let(:motifs_presenter) { described_class.new(motifs_application) }

    context 'when mandatory motifs_exclusion attribute has no data' do
      before do
        create(:market_attribute,
          key: 'motifs_exclusion_mandatory_field',
          mandatory: true,
          category_key: 'motifs_exclusion',
          subcategory_key: 'motifs_exclusion_fiscales',
          input_type: :file_upload,
          public_markets: [motifs_market])
      end

      it 'returns true' do
        expect(motifs_presenter.missing_mandatory_motifs_exclusion?).to be true
      end
    end

    context 'when mandatory motifs_exclusion attribute has data' do
      let!(:motifs_attr) do
        create(:market_attribute,
          key: 'motifs_exclusion_mandatory_field_with_data',
          mandatory: true,
          category_key: 'motifs_exclusion',
          subcategory_key: 'motifs_exclusion_fiscales',
          input_type: :file_upload,
          public_markets: [motifs_market])
      end

      before do
        response = MarketAttributeResponse::FileUpload.create!(
          market_application: motifs_application,
          market_attribute: motifs_attr
        )
        response.documents.attach(
          io: StringIO.new('test content'),
          filename: 'test.pdf',
          content_type: 'application/pdf'
        )
      end

      it 'returns false' do
        motifs_application.reload
        expect(motifs_presenter.missing_mandatory_motifs_exclusion?).to be false
      end
    end

    context 'when there are no mandatory motifs_exclusion attributes' do
      before do
        create(:market_attribute,
          key: 'optional_motifs_field',
          mandatory: false,
          category_key: 'motifs_exclusion',
          subcategory_key: 'motifs_exclusion_fiscales',
          public_markets: [motifs_market])
      end

      it 'returns false' do
        expect(motifs_presenter.missing_mandatory_motifs_exclusion?).to be false
      end
    end

    context 'when there are no motifs_exclusion attributes at all' do
      let(:no_motifs_market) { create(:public_market, :completed, editor:) }
      let(:no_motifs_application) { create(:market_application, public_market: no_motifs_market) }
      let(:no_motifs_presenter) { described_class.new(no_motifs_application) }

      before do
        create(:market_attribute,
          key: 'other_category_field',
          mandatory: true,
          category_key: 'identite_entreprise',
          subcategory_key: 'identification',
          public_markets: [no_motifs_market])
      end

      it 'returns false' do
        expect(no_motifs_presenter.missing_mandatory_motifs_exclusion?).to be false
      end
    end
  end

  describe 'with soft-deleted market attributes' do
    let(:active_attribute) do
      create(:market_attribute,
        key: 'active_field',
        category_key: 'identite_entreprise',
        subcategory_key: 'identification',
        deleted_at: nil)
    end

    let(:soft_deleted_attribute) do
      create(:market_attribute,
        key: 'deleted_field',
        category_key: 'identite_entreprise',
        subcategory_key: 'identification',
        deleted_at: 1.day.ago)
    end

    let(:public_market_with_soft_deleted) do
      create(:public_market, :completed, editor:).tap do |pm|
        pm.market_attributes << [active_attribute, soft_deleted_attribute]
      end
    end

    let(:market_application) { create(:market_application, public_market: public_market_with_soft_deleted) }
    let(:presenter) { described_class.new(market_application) }

    it 'includes soft-deleted attributes in all_market_attributes' do
      attributes = presenter.send(:all_market_attributes)

      expect(attributes).to include(active_attribute)
      expect(attributes).to include(soft_deleted_attribute)
    end

    it 'includes soft-deleted attributes in fields structure' do
      fields = presenter.fields_by_category_and_subcategory

      all_field_keys = fields.values.flat_map(&:values).flatten

      expect(all_field_keys).to include(active_attribute.key)
      expect(all_field_keys).to include(soft_deleted_attribute.key)
    end

    it 'creates responses for both active and soft-deleted attributes' do
      response_for_active = presenter.market_attribute_response_for(active_attribute)
      response_for_deleted = presenter.market_attribute_response_for(soft_deleted_attribute)

      expect(response_for_active).to be_present
      expect(response_for_deleted).to be_present
    end
  end
end
