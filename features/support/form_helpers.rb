# frozen_string_literal: true

module FormHelpers
  def fill_in_visible_fields
    fill_in_text_fields
    fill_in_email_fields
    fill_in_phone_fields
    fill_in_textarea_fields
    check_all_checkboxes
  end

  def fill_in_text_fields
    page.all('input[type="text"]').each do |field|
      next if field[:readonly] || field[:disabled] || field[:name]&.include?('siret')

      field.set('Test Value') if field.value.blank?
    end
  end

  def fill_in_email_fields
    page.all('input[type="email"]').each { |f| f.set('test@example.com') if f.value.blank? }
  end

  def fill_in_phone_fields
    page.all('input[type="tel"]').each { |f| f.set('01 23 45 67 89') if f.value.blank? }
  end

  def fill_in_textarea_fields
    page.all('textarea').each { |f| f.set('Test description') if f.value.blank? }
  end

  def check_all_checkboxes
    page.all('input[type="checkbox"]').each { |cb| cb.check unless cb.checked? }
  end

  def attach_test_file(filename = 'test_upload.pdf')
    test_file_path = Rails.root.join("tmp/#{filename}")
    File.write(test_file_path, '%PDF-1.4 test content')
    page.first('input[type="file"]').attach_file(test_file_path)
  end

  def attach_test_files_to_all_inputs(filename = 'test_upload.pdf')
    test_file_path = Rails.root.join("tmp/#{filename}")
    File.write(test_file_path, '%PDF-1.4 test content')
    page.all('input[type="file"]').each do |file_input|
      next if file_input[:disabled]

      file_input.attach_file(test_file_path)
    end
  end
end

World(FormHelpers)
