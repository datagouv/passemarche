# frozen_string_literal: true

require 'rails_helper'

RSpec.describe FieldTranslationImport::UpdateTranslationFile, type: :interactor do
  describe '.call' do
    it 'sets translation_file_updated to false' do
      context = Interactor::Context.build(statistics: {})

      result = described_class.call(context)

      expect(result).to be_success
      expect(result.statistics[:translation_file_updated]).to be false
    end
  end
end
