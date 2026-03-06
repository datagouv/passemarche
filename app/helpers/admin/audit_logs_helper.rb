# frozen_string_literal: true

module Admin::AuditLogsHelper
  IGNORED_ATTRIBUTES = %w[updated_at created_at id].freeze

  EVENT_BADGE_CLASSES = {
    'create' => 'fr-badge--success',
    'update' => 'fr-badge--info',
    'archive' => 'fr-badge--warning',
    'destroy' => 'fr-badge--error'
  }.freeze

  def resolved_event(version)
    return version.event unless version.event == 'update'

    changes = version_changes(version)
    deleted_at_change = changes['deleted_at']
    return 'archive' if deleted_at_change && deleted_at_change.first.nil? && deleted_at_change.second.present?

    'update'
  end

  def version_event_badge(version)
    event = resolved_event(version)
    badge_class = EVENT_BADGE_CLASSES[event]
    tag.span(t("admin.audit_logs.events.#{event}"), class: "fr-badge fr-badge--sm #{badge_class}")
  end

  def version_admin_user(version)
    return '-' if version.whodunnit.blank?

    AdminUser.find_by(id: version.whodunnit)&.email || "Utilisateur ##{version.whodunnit}"
  end

  def version_scope_badge(version)
    changes = version_changes(version)
    return if changes.blank?

    relevant_keys = changes.keys - IGNORED_ATTRIBUTES
    has_buyer = relevant_keys.any? { |k| k.start_with?('buyer_') }
    has_candidate = relevant_keys.any? { |k| k.start_with?('candidate_') }

    if has_buyer && has_candidate
      t('admin.audit_logs.scopes.both')
    elsif has_buyer
      t('admin.audit_logs.scopes.buyer')
    elsif has_candidate
      t('admin.audit_logs.scopes.candidate')
    end
  end

  def version_category_label(version)
    item = version.item
    return version.item_type unless item

    category_key = item.category_key
    return category_key.humanize unless category_key

    Category.find_by(key: category_key)&.buyer_label || category_key.humanize
  end

  def version_changes(version)
    version.changeset || {}
  end

  def categorized_changes(changes)
    relevant = changes.except(*IGNORED_ATTRIBUTES)
    {
      buyer: relevant.select { |k, _| k.start_with?('buyer_') },
      candidate: relevant.select { |k, _| k.start_with?('candidate_') },
      other: relevant.reject { |k, _| k.start_with?('buyer_', 'candidate_') }
    }
  end

  def human_attribute_label(attr_name)
    t("admin.audit_logs.attribute_labels.#{attr_name}", default: attr_name.humanize)
  end

  def format_change_value(value)
    return '-' if value.nil?
    return t("admin.shared.#{value ? 'yes' : 'no'}") if [true, false].include?(value)

    value.to_s
  end
end
