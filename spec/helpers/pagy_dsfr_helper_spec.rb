# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PagyDsfrHelper, type: :helper do
  let(:pagy) do
    double('Pagy',
      last: 5,
      page: 3,
      previous: 2,
      next: 4)
  end

  before do
    allow(pagy).to receive(:send).with(:series).and_return([1, 2, '3', 4, :gap, 5])
    allow(pagy).to receive(:page_url).with(:first).and_return('/candidate/dashboard?page=1')
    allow(pagy).to receive(:page_url).with(:previous).and_return('/candidate/dashboard?page=2')
    allow(pagy).to receive(:page_url).with(:next).and_return('/candidate/dashboard?page=4')
    allow(pagy).to receive(:page_url).with(:last).and_return('/candidate/dashboard?page=5')
    allow(pagy).to receive(:page_url).with(1).and_return('/candidate/dashboard?page=1')
    allow(pagy).to receive(:page_url).with(2).and_return('/candidate/dashboard?page=2')
    allow(pagy).to receive(:page_url).with(4).and_return('/candidate/dashboard?page=4')
    allow(pagy).to receive(:page_url).with(5).and_return('/candidate/dashboard?page=5')
  end

  describe '#pagy_dsfr_nav' do
    context 'when there is only one page' do
      before { allow(pagy).to receive(:last).and_return(1) }

      it 'returns an empty string' do
        expect(helper.pagy_dsfr_nav(pagy)).to be_empty
      end
    end

    context 'when there are multiple pages' do
      subject(:html) { helper.pagy_dsfr_nav(pagy) }

      it 'renders a DSFR pagination nav' do
        expect(html).to include('fr-pagination')
        expect(html).to include('fr-pagination__list')
      end

      it 'marks the current page with aria-current' do
        expect(html).to include('aria-current="page"')
        expect(html).to include('>3<')
      end

      it 'renders gaps as ellipsis' do
        expect(html).to include('…')
      end

      it 'renders page links' do
        expect(html).to include('page=1')
        expect(html).to include('page=2')
        expect(html).to include('page=4')
        expect(html).to include('page=5')
      end

      context 'on the first page' do
        before do
          allow(pagy).to receive(:page).and_return(1)
          allow(pagy).to receive(:previous).and_return(nil)
          allow(pagy).to receive(:page_url).with(3).and_return('/candidate/dashboard?page=3')
          allow(pagy).to receive(:send).with(:series).and_return(['1', 2, 3])
        end

        it 'disables the first and prev links' do
          disabled = html.scan(/<span[^>]+aria-disabled="true"[^>]*>/)
          expect(disabled).to include(match(/fr-pagination__link--first/))
          expect(disabled).to include(match(/fr-pagination__link--prev/))
        end
      end

      context 'on the last page' do
        before do
          allow(pagy).to receive(:page).and_return(5)
          allow(pagy).to receive(:next).and_return(nil)
          allow(pagy).to receive(:send).with(:series).and_return([1, 2, '5'])
        end

        it 'disables the next and last links' do
          disabled = html.scan(/<span[^>]+aria-disabled="true"[^>]*>/)
          expect(disabled).to include(match(/fr-pagination__link--next/))
          expect(disabled).to include(match(/fr-pagination__link--last/))
        end
      end
    end
  end
end
