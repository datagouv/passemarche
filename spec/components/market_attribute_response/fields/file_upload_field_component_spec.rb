# frozen_string_literal: true

require 'rails_helper'

RSpec.describe MarketAttributeResponse::Fields::FileUploadFieldComponent, type: :component do
  let(:market_application) { create(:market_application) }
  let(:market_attribute) { create(:market_attribute, :file_upload) }
  let(:attribute_response) do
    create(:market_attribute_response_file_upload,
      market_application:,
      market_attribute:)
  end
  let(:form) { double('FormBuilder', object: attribute_response) }

  before do
    allow(form).to receive(:label).and_return('<label>Label</label>'.html_safe)
    allow(form).to receive(:file_field).and_return('<input type="file">'.html_safe)
    allow(form).to receive(:hidden_field).and_return('<input type="hidden">'.html_safe)
  end

  describe '#documents' do
    it 'returns the attribute_response documents' do
      component = described_class.new(form:, attribute_response:)

      expect(component.documents).to eq(attribute_response.documents)
    end
  end

  describe '#market_application_identifier' do
    it 'returns the market application identifier' do
      component = described_class.new(form:, attribute_response:)

      expect(component.market_application_identifier).to eq(market_application.identifier)
    end
  end

  describe '#field_id' do
    it 'returns unique field id based on response id' do
      component = described_class.new(form:, attribute_response:)

      expect(component.field_id).to eq("upload-#{attribute_response.id}")
    end
  end

  describe '#label_text' do
    context 'with default label' do
      it 'returns default label text' do
        component = described_class.new(form:, attribute_response:)

        expect(component.label_text).to eq('Ajouter vos documents')
      end
    end

    context 'with custom label' do
      it 'returns custom label text' do
        component = described_class.new(form:, attribute_response:, label: 'Custom Label')

        expect(component.label_text).to eq('Custom Label')
      end
    end
  end

  describe '#hint_text' do
    it 'includes max file size' do
      component = described_class.new(form:, attribute_response:)

      expect(component.hint_text).to include('Mo')
    end

    it 'includes supported formats' do
      component = described_class.new(form:, attribute_response:)

      expect(component.hint_text).to include('pdf')
      expect(component.hint_text).to include('jpg')
      expect(component.hint_text).to include('png')
    end
  end

  describe '#accepted_formats' do
    it 'returns accepted file formats from centralized config' do
      component = described_class.new(form:, attribute_response:)

      expect(component.accepted_formats).to start_with('.')
      expect(component.accepted_formats).to include(',')

      # Check common formats are present
      expect(component.accepted_formats).to include('.pdf')
      expect(component.accepted_formats).to include('.jpg')
      expect(component.accepted_formats).to include('.png')
    end
  end

  describe '#base_errors?' do
    context 'with no errors' do
      it 'returns false' do
        component = described_class.new(form:, attribute_response:)

        expect(component.base_errors?).to be false
      end
    end

    context 'with base errors' do
      it 'returns true' do
        attribute_response.errors.add(:base, 'An error occurred')
        component = described_class.new(form:, attribute_response:)

        expect(component.base_errors?).to be true
      end
    end
  end

  describe 'rendering' do
    it 'renders the upload container with direct-upload controller' do
      component = described_class.new(form:, attribute_response:)

      render_inline(component)

      expect(page).to have_css('[data-controller="direct-upload"]')
    end

    it 'renders the progress bar component' do
      component = described_class.new(form:, attribute_response:)

      render_inline(component)

      expect(page).to have_css('[data-direct-upload-target="progress"]')
    end

    it 'renders the files list container' do
      component = described_class.new(form:, attribute_response:)

      render_inline(component)

      expect(page).to have_css('[data-direct-upload-target="filesList"]')
    end

    context 'with deletable: true' do
      it 'sets deletable data attribute to true' do
        component = described_class.new(form:, attribute_response:, deletable: true)

        render_inline(component)

        expect(page).to have_css('[data-direct-upload-deletable-value="true"]')
      end
    end

    context 'with deletable: false' do
      it 'sets deletable data attribute to false' do
        component = described_class.new(form:, attribute_response:, deletable: false)

        render_inline(component)

        expect(page).to have_css('[data-direct-upload-deletable-value="false"]')
      end
    end

    context 'with base errors' do
      it 'renders error message' do
        attribute_response.errors.add(:base, 'File too large')
        component = described_class.new(form:, attribute_response:)

        render_inline(component)

        expect(page).to have_css('.fr-error-text', text: 'File too large')
      end
    end
  end
end
