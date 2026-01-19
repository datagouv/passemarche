require 'rails_helper'

RSpec.describe ScanDocumentJob, type: :job do
  let(:blob) { ActiveStorage::Blob.create_and_upload!(io: StringIO.new('test'), filename: 'test.pdf') }

  describe '#perform' do
    context 'when file is safe' do
      before do
        allow(FileSecurityScanner).to receive(:scan!).and_return(
          scanned_at: Time.current.iso8601,
          scan_safe: true,
          scanner: 'clamav'
        )
      end

      it 'marks blob as safe' do
        described_class.perform_now(blob.id)
        expect(blob.reload.metadata['scan_safe']).to be true
      end

      it 'stores scan timestamp' do
        described_class.perform_now(blob.id)
        expect(blob.reload.metadata['scanned_at']).to be_present
      end
    end

    context 'when malware is detected' do
      before do
        allow(FileSecurityScanner).to receive(:scan!).and_raise(
          FileSecurityScanner::SecurityError.new('Malware détecté: EICAR-Test-File')
        )
      end

      it 'marks blob as unsafe' do
        described_class.perform_now(blob.id)
        expect(blob.reload.metadata['scan_safe']).to be false
      end

      it 'stores error message' do
        described_class.perform_now(blob.id)
        expect(blob.reload.metadata['scan_error']).to eq('Malware détecté: EICAR-Test-File')
      end

      it 'stores scan timestamp' do
        described_class.perform_now(blob.id)
        expect(blob.reload.metadata['scanned_at']).to be_present
      end

      it 'logs error message' do
        allow(Rails.logger).to receive(:error)
        described_class.perform_now(blob.id)
        expect(Rails.logger).to have_received(:error).with(/🦠 Malware détecté/)
      end
    end
  end
end
