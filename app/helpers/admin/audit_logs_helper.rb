# frozen_string_literal: true

module Admin::AuditLogsHelper
  EVENT_BADGE_CLASSES = {
    'create' => 'fr-badge--success',
    'update' => 'fr-badge--info',
    'destroy' => 'fr-badge--error'
  }.freeze

  def version_event_badge(event)
    badge_class = EVENT_BADGE_CLASSES[event]
    tag.span(t("admin.audit_logs.events.#{event}"), class: "fr-badge fr-badge--sm #{badge_class}")
  end

  def version_admin_user(version)
    return '-' if version.whodunnit.blank?

    AdminUser.find_by(id: version.whodunnit)&.email || "Utilisateur ##{version.whodunnit}"
  end

  def version_scope_badge(version)
    changes = version_changes(version)
    return unless changes

    has_buyer = changes.keys.any? { |k| k.start_with?('buyer_') }
    has_candidate = changes.keys.any? { |k| k.start_with?('candidate_') }

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

    item.category_key&.humanize
  end

  def version_changes(version)
    return {} unless version.object_changes

    YAML.safe_load(version.object_changes, permitted_classes: [Time, Date, ActiveSupport::TimeWithZone])
  end

  def human_attribute_label(attr_name)
    t("admin.audit_logs.attribute_labels.#{attr_name}", default: attr_name.humanize)
  end

  def format_change_value(value)
    return '-' if value.nil?
    return value ? 'Oui' : 'Non' if [true, false].include?(value)

    value.to_s
  end
end
