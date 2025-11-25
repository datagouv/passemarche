require 'rails_helper'

RSpec.describe MarketAttributeResponse::CheckboxWithDocument, type: :model do
  let(:market_application) { create(:market_application) }
  let(:market_attribute) { create(:market_attribute) }
  let(:response) do
    described_class.new(
      market_application:,
      market_attribute:
    )
  end

  describe 'checked attribute' do
    it 'is invalid when checked is nil' do
      response.checked = nil
      expect(response).not_to be_valid
      expect(response.errors[:checked]).to be_present
    end

    it 'is valid when checked is true' do
      response.checked = true
      expect(response).to be_valid
    end

    it 'is valid when checked is false' do
      response.checked = false
      expect(response).to be_valid
    end
  end

  describe 'file upload' do
    it 'is valid without a file' do
      response.checked = true
      expect(response.documents.attached?).to be_falsey
      expect(response).to be_valid
    end

    it 'is valid with a file attached' do
      response.checked = true
      response.documents.attach(
        io: StringIO.new('dummy content'),
        filename: 'test.pdf',
        content_type: 'application/pdf'
      )
      expect(response.documents.attached?).to be_truthy
      expect(response).to be_valid
    end

    it 'accepts any allowed content type' do
      response.checked = true
      response.documents.attach(
        io: StringIO.new('dummy content'),
        filename: 'test.png',
        content_type: 'image/png'
      )
      expect(response).to be_valid
    end
  end

  describe 'combination checked/file validation' do
    it 'is valid when unchecked and no files' do
      response.checked = false
      expect(response.documents.attached?).to be_falsey
      expect(response).to be_valid
    end

    it 'is valid when checked and no files' do
      response.checked = true
      expect(response.documents.attached?).to be_falsey
      expect(response).to be_valid
    end

    it 'is valid when checked and files attached' do
      response.checked = true
      response.documents.attach(
        io: StringIO.new('dummy content'),
        filename: 'test.pdf',
        content_type: 'application/pdf'
      )
      expect(response).to be_valid
    end

    it 'is invalid when unchecked and files attached' do
      response.checked = false
      response.documents.attach(
        io: StringIO.new('dummy content'),
        filename: 'test.pdf',
        content_type: 'application/pdf'
      )
      expect(response).not_to be_valid
    end
  end
end
