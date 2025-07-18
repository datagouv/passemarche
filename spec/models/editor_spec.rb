# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Editor, type: :model do
  subject { build(:editor) }

  describe 'validations' do
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_uniqueness_of(:name) }
    it { is_expected.to validate_presence_of(:client_id) }
    it { is_expected.to validate_uniqueness_of(:client_id) }
    it { is_expected.to validate_presence_of(:client_secret) }
  end

  describe 'scopes' do
    before do
      Editor.delete_all
    end

    let!(:authorized_but_inactive_editor) { create(:authorized_editor, active: false) }
    let!(:unauthorized_editor) { create(:editor, authorized: false) }
    let!(:inactive_editor) { create(:inactive_editor) }
    let!(:authorized_and_active_editor) { create(:authorized_and_active_editor) }

    describe '.authorized' do
      it 'returns only authorized editors' do
        expect(described_class.authorized).to contain_exactly(authorized_but_inactive_editor, authorized_and_active_editor)
      end
    end

    describe '.active' do
      it 'returns only active editors' do
        expect(described_class.active).to contain_exactly(unauthorized_editor, authorized_and_active_editor)
      end
    end

    describe '.authorized_and_active' do
      it 'returns only editors that are both authorized and active' do
        expect(described_class.authorized_and_active).to contain_exactly(authorized_and_active_editor)
      end
    end
  end

  describe 'instance methods' do
    describe '#authorized_and_active?' do
      context 'when editor is authorized and active' do
        let(:editor) { create(:authorized_and_active_editor) }

        it 'returns true' do
          expect(editor.authorized_and_active?).to be true
        end
      end

      context 'when editor is authorized but inactive' do
        let(:editor) { create(:authorized_editor, active: false) }

        it 'returns false' do
          expect(editor.authorized_and_active?).to be false
        end
      end

      context 'when editor is active but unauthorized' do
        let(:editor) { create(:editor, authorized: false) }

        it 'returns false' do
          expect(editor.authorized_and_active?).to be false
        end
      end

      context 'when editor is neither authorized nor active' do
        let(:editor) { create(:editor, authorized: false, active: false) }

        it 'returns false' do
          expect(editor.authorized_and_active?).to be false
        end
      end
    end
  end

  describe 'factory' do
    it 'creates a valid editor' do
      editor = build(:editor)
      expect(editor).to be_valid
    end

    it 'creates unique client_ids for multiple editors' do
      editor1 = create(:editor)
      editor2 = create(:editor)
      expect(editor1.client_id).not_to eq(editor2.client_id)
    end

    it 'creates unique names for multiple editors' do
      editor1 = create(:editor)
      editor2 = create(:editor)
      expect(editor1.name).not_to eq(editor2.name)
    end

    describe 'traits' do
      it 'creates an authorized editor' do
        editor = create(:authorized_editor)
        expect(editor.authorized?).to be true
        expect(editor.active?).to be true
      end

      it 'creates an inactive editor' do
        editor = create(:inactive_editor)
        expect(editor.active?).to be false
      end

      it 'creates an authorized and active editor' do
        editor = create(:authorized_and_active_editor)
        expect(editor.authorized?).to be true
        expect(editor.active?).to be true
      end
    end
  end

  describe 'database constraints' do
    it 'enforces unique name constraint' do
      create(:editor, name: 'Test Editor')
      duplicate_editor = build(:editor, name: 'Test Editor')
      expect(duplicate_editor).not_to be_valid
      expect(duplicate_editor.errors[:name]).to be_present
    end

    it 'enforces unique client_id constraint' do
      existing_editor = create(:editor)
      duplicate_editor = build(:editor, client_id: existing_editor.client_id)
      expect(duplicate_editor).not_to be_valid
      expect(duplicate_editor.errors[:client_id]).to be_present
    end

    it 'requires all mandatory fields' do
      editor = Editor.new
      expect(editor).not_to be_valid
      expect(editor.errors[:name]).to be_present
      expect(editor.errors[:client_id]).to be_present
      expect(editor.errors[:client_secret]).to be_present
    end
  end

  describe 'default values' do
    it 'sets default values correctly' do
      editor = Editor.new(name: 'Test', client_id: 'test_id', client_secret: 'secret')
      expect(editor.authorized).to be false
      expect(editor.active).to be true
    end
  end
end
