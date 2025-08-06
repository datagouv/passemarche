# frozen_string_literal: true

module UniqueAssociationValidator
  extend ActiveSupport::Concern

  class_methods do
    def validates_uniqueness_of_association(*associations)
      associations.each do |association|
        validate :"validate_unique_#{association}"
        define_method :"validate_unique_#{association}" do
          ids = send("#{association.to_s.singularize}_ids")
          duplicate_ids = find_duplicate_ids(ids)

          add_duplication_error(association, duplicate_ids) if duplicate_ids.any?
        end
      end
    end
  end

  private

  def find_duplicate_ids(ids)
    ids.group_by(&:itself).select { |_, group| group.many? }.keys
  end

  def add_duplication_error(association, duplicate_ids)
    model_class = association.to_s.singularize.camelize.constantize
    names = find_duplicate_names(model_class, duplicate_ids)
    message = names.any? ? "contains duplicates: #{names.join(', ')}" : 'contains duplicate associations'
    errors.add(association, message)
  rescue NameError
    errors.add(association, 'contains duplicate associations')
  end

  def find_duplicate_names(model_class, duplicate_ids)
    if model_class.column_names.include?('key')
      model_class.where(id: duplicate_ids).pluck(:key)
    elsif model_class.column_names.include?('name')
      model_class.where(id: duplicate_ids).pluck(:name)
    else
      []
    end
  end
end
