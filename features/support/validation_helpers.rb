# frozen_string_literal: true

module ValidationHelpers
  def file_format_error_present?
    page.has_content?('format') ||
      page.has_css?('.fr-error-text') ||
      page.has_content?('invalide')
  end

  def validation_error_present?
    page.has_css?('.fr-error-text') ||
      page.has_content?('erreur') ||
      page.has_content?('error') ||
      page.has_content?('invalide') ||
      page.has_content?('requis')
  end

  def on_expected_path?(path_pattern)
    page.has_current_path?(path_pattern, ignore_query: true)
  end
end

World(ValidationHelpers)
