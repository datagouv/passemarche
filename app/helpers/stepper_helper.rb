module StepperHelper
  def stepper(current_step:, steps:, i18n_scope:)
    current_step = current_step.to_sym
    return unless steps.include?(current_step)

    step_number = steps.index(current_step) + 1
    total_steps = steps.size
    step_label = t("#{i18n_scope}.#{current_step}")

    content_tag(:div, class: 'fr-stepper') do
      safe_join([
        stepper_title(step_label, step_number, total_steps),
        stepper_steps_div(step_number, total_steps),
        stepper_details(current_step, steps, i18n_scope)
      ])
    end
  end

  private

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

  def stepper_details(current_step, steps, i18n_scope)
    content_tag(:p, class: 'fr-stepper__details') do
      next_step_index = steps.index(current_step) + 1
      if next_step_index < steps.size
        next_step_label = t("#{i18n_scope}.#{steps[next_step_index]}")
        safe_join([
          content_tag(:span, 'Étape suivante :', class: 'fr-text--bold'),
          " #{next_step_label}"
        ])
      else
        ''
      end
    end
  end
end
