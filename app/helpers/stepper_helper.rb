module StepperHelper
  def stepper(current_step:, steps:, i18n_scope:, **options)
    current_step = current_step.to_sym
    return unless steps.include?(current_step)

    step_data = build_step_data(current_step, steps, i18n_scope, options)
    render_stepper_content(step_data)
  end

  def build_step_data(current_step, steps, i18n_scope, options)
    {
      current_step:,
      steps:,
      step_number: steps.index(current_step) + 1,
      total_steps: steps.size,
      step_label: options[:step_title] || resolve_step_title(current_step, i18n_scope),
      next_step_title: options[:next_step_title] || resolve_next_step_title(current_step, steps, i18n_scope),
      step_subtitle: options[:step_subtitle],
      show_separator: options[:show_separator] || false,
      i18n_scope:
    }
  end

  def render_stepper_content(data)
    content_tag(:div, class: 'fr-stepper') do
      safe_join(stepper_content_elements(data))
    end
  end

  private

  # rubocop:disable Metrics/AbcSize
  def stepper_content_elements(data)
    [
      stepper_title(data[:step_label], data[:step_number], data[:total_steps]),
      stepper_steps_div(data[:step_number], data[:total_steps]),
      stepper_details(data[:current_step], data[:steps], data[:next_step_title]),
      content_tag(:div, nil, class: 'fr-mb-5w'),
      stepper_page_header(data[:current_step], data[:i18n_scope], data[:step_subtitle]),
      (content_tag(:hr, nil, class: 'stepper__separator') if data[:show_separator])
    ]
  end
  # rubocop:enable Metrics/AbcSize

  def stepper_title(step_label, step_number, total_steps)
    content_tag(:h2, class: 'fr-stepper__title') do
      safe_join([
        step_label,
        content_tag(:span, "Étape #{step_number} sur #{total_steps}", class: 'fr-stepper__state')
      ], ' ')
    end
  end

  def stepper_steps_div(step_number, total_steps)
    content_tag(
      :div,
      '',
      class: 'fr-stepper__steps',
      data: {
        'fr-current-step': step_number,
        'fr-steps': total_steps
      }
    )
  end

  def stepper_details(current_step, steps, next_step_title)
    content_tag(:p, class: 'fr-stepper__details') do
      next_step_index = steps.index(current_step) + 1
      if next_step_index < steps.size && next_step_title.present?
        safe_join([
          content_tag(:span, 'Étape suivante :', class: 'fr-text--bold'),
          " #{next_step_title}"
        ])
      else
        ''
      end
    end
  end

  def stepper_page_header(step, i18n_scope, custom_subtitle)
    if i18n_scope.start_with?('buyer')
      buyer_page_header(step, custom_subtitle)
    else
      candidate_page_header(step, i18n_scope, custom_subtitle)
    end
  end

  def buyer_page_header(step, custom_subtitle)
    page_title = t("buyer.public_markets.#{step}.title", default: '')
    page_subtitle = custom_subtitle || t("buyer.public_markets.#{step}.subtitle", default: '')

    return if page_title.blank? && page_subtitle.blank?

    render_page_header(page_title, page_subtitle)
  end

  def candidate_page_header(step, i18n_scope, custom_subtitle)
    page_title = resolve_step_title(step, i18n_scope)

    page_subtitle =
      simple_format(custom_subtitle ||
      t("candidate.market_applications.#{step}.subtitle", default: nil))

    return if page_title.blank?

    render_page_header(page_title, page_subtitle)
  end

  def render_page_header(title, subtitle)
    content_tag(:div, class: 'fr-mb-2w') do
      safe_join([
        (content_tag(:h1, title, class: 'fr-h1 fr-mb-1w') if title.present?),
        (content_tag(:p, subtitle, class: 'fr-text--lg fr-mb-0') if subtitle.present?)
      ].compact)
    end
  end

  def resolve_step_title(step, i18n_scope)
    if i18n_scope.start_with?('buyer')
      t("buyer.public_markets.steps.#{step}")
    else
      fallback = t("candidate.market_applications.steps.#{step}", default: step.to_s.humanize)
      category_label(step, scope: :candidate, default: fallback)
    end
  end

  def resolve_next_step_title(current_step, steps, i18n_scope)
    next_step_index = steps.index(current_step) + 1
    return nil if next_step_index >= steps.size

    next_step = steps[next_step_index]
    resolve_step_title(next_step, i18n_scope)
  end
end
