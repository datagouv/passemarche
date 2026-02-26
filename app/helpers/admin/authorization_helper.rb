# frozen_string_literal: true

module Admin
  module AuthorizationHelper
    def admin_action_link_to(label, url, **options)
      if current_user_can_modify?
        link_to(label, url, **options)
      else
        content_tag(:button, label, class: options[:class], disabled: true, type: 'button')
      end
    end
  end
end
