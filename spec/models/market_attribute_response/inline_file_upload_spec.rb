require 'rails_helper'

RSpec.describe MarketAttributeResponse::InlineFileUpload, type: :model do
  let(:market_application) { create(:market_application) }
  let(:market_attribute) { create(:market_attribute, input_type: 'inline_file_upload') }
  let(:inline_file_upload) do
    MarketAttributeResponse::InlineFileUpload.new(
      market_application:,
      market_attribute:
    )
  end

  describe 'inheritance' do
    it 'inherits from FileUpload' do
      expect(described_class.superclass).to eq(MarketAttributeResponse::FileUpload)
    end

    it 'includes FileAttachable concern through parent' do
      expect(inline_file_upload).to respond_to(:documents)
    end
  end

  describe 'validation' do
    it 'allows no documents attached' do
      expect(inline_file_upload).to be_valid
    end
  end

  describe 'STI type' do
    it 'sets correct type' do
      inline_file_upload.save
      expect(inline_file_upload.type).to eq('InlineFileUpload')
    end
  end
end
