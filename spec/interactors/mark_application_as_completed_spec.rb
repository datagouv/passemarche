# frozen_string_literal: true

require 'rails_helper'

RSpec.describe MarkApplicationAsCompleted, type: :interactor do
  let(:market_application) { create(:market_application, siret: nil) }

  describe '.call' do
    subject { described_class.call(market_application:) }

    context 'when market application is not completed' do
      it 'succeeds' do
        expect(subject).to be_success
      end

      it 'sets completed_at timestamp' do
        expect { subject }
          .to change { market_application.reload.completed_at }
          .from(nil).to(be_within(1.second).of(Time.current))
      end

      it 'sets completed_at in context' do
        result = subject
        expect(result.completed_at).to be_within(1.second).of(Time.current)
      end
    end

    context 'when market application is already completed' do
      let(:market_application) { create(:market_application, siret: nil, completed_at: 1.hour.ago) }

      it 'fails' do
        expect(subject).to be_failure
      end

      it 'provides error message' do
        expect(subject.message).to eq('Application already completed')
      end
    end
  end
end
