# frozen_string_literal: true

module PagyDsfrHelper
  def pagy_dsfr_nav(pagy)
    return ''.html_safe if pagy.last <= 1

    items = [first_link(pagy), prev_link(pagy)]
    pagy.send(:series).each { |item| items << series_item(pagy, item) }
    items += [next_link(pagy), last_link(pagy)]
    nav_wrapper(safe_join(items))
  end

  private

  def nav_wrapper(inner)
    aria_label = t('pagy.nav.aria_label')
    content_tag(:nav, role: 'navigation', class: 'fr-pagination fr-mt-4w', aria: { label: aria_label }) do
      content_tag(:ul, inner, class: 'fr-pagination__list')
    end
  end

  def pagination_link(label, classes:, url: nil, aria: nil)
    content_tag(:li) do
      options = { class: classes }
      options[:aria] = aria if aria
      url ? content_tag(:a, label, href: url, **options) : content_tag(:span, label, **options)
    end
  end

  def first_link(pagy)
    pagination_link(
      t('pagy.nav.first'),
      url: pagy.previous && pagy.page_url(:first),
      classes: 'fr-pagination__link fr-pagination__link--first',
      aria: pagy.previous ? nil : { disabled: true }
    )
  end

  def prev_link(pagy)
    pagination_link(
      t('pagy.nav.prev'),
      url: pagy.previous && pagy.page_url(:previous),
      classes: 'fr-pagination__link fr-pagination__link--prev fr-pagination__link--lg-label',
      aria: pagy.previous ? nil : { disabled: true }
    )
  end

  def series_item(pagy, item)
    case item
    when String
      pagination_link(item, classes: 'fr-pagination__link', aria: { current: 'page' })
    when :gap
      pagination_link('…', classes: 'fr-pagination__link', aria: { hidden: true })
    else
      pagination_link(item.to_s, url: pagy.page_url(item), classes: 'fr-pagination__link')
    end
  end

  def next_link(pagy)
    pagination_link(
      t('pagy.nav.next'),
      url: pagy.next && pagy.page_url(:next),
      classes: 'fr-pagination__link fr-pagination__link--next fr-pagination__link--lg-label',
      aria: pagy.next ? nil : { disabled: true }
    )
  end

  def last_link(pagy)
    pagination_link(
      t('pagy.nav.last'),
      url: pagy.next && pagy.page_url(:last),
      classes: 'fr-pagination__link fr-pagination__link--last',
      aria: pagy.next ? nil : { disabled: true }
    )
  end
end
