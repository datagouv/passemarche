require 'rails_helper'

RSpec.describe DsfrFileHelper, type: :helper do
  let(:blob) { ActiveStorage::Blob.create_and_upload!(io: StringIO.new('test'), filename: 'test.pdf') }
  let(:attachment) { double('Attachment', blob:, id: 42) }

  before do
    allow(blob).to receive(:metadata).and_return(metadata)
    allow(helper).to receive(:antivirus_enabled?).and_return(true)
  end

  context 'when safe' do
    let(:metadata) { { 'scan_safe' => true, 'scanned_at' => Time.zone.now.iso8601 } }

    it 'renders custom security badge with shield icon and safe label' do
      html = helper.dsfr_malware_badge(attachment)
      expect(html).to include('fr-badge--security-safe')
      expect(html).to include('fr-badge--no-icon')
      expect(html).to include('fr-icon-shield-fill')
      expect(html).to include(I18n.t('malware_scan.label.safe'))
    end
  end

  context 'when unsafe' do
    let(:metadata) { { 'scan_safe' => false, 'scanned_at' => Time.zone.now.iso8601 } }

    it 'renders custom security badge with warning icon and unsafe label' do
      html = helper.dsfr_malware_badge(attachment)
      expect(html).to include('fr-badge--security-unsafe')
      expect(html).to include('fr-badge--no-icon')
      expect(html).to include('fr-icon-warning-line')
      expect(html).to include(I18n.t('malware_scan.label.unsafe'))
    end
  end

  context 'when scanning' do
    let(:metadata) { {} }

    it 'renders custom security badge with time icon and scanning label' do
      html = helper.dsfr_malware_badge(attachment)
      expect(html).to include('fr-badge--security-scanning')
      expect(html).to include('fr-badge--no-icon')
      expect(html).to include('fr-icon-time-line')
      expect(html).to include(I18n.t('malware_scan.label.scanning'))
    end
  end
end
