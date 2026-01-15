module DsfrFileHelper
  def dsfr_malware_badge(document, **options)
    safety_state = document_safety_state(document)
    return if safety_state == 'not_scanned'

    label = badge_label_with_icon(safety_state)
    data_attrs = safety_state == 'scanning' ? { turbo_frame: "scan-status-#{document.id}" } : {}

    # Use only custom classes to avoid DSFR default icons
    css_classes = [
      'fr-badge',
      'fr-badge--sm',
      'fr-badge--no-icon',
      "fr-badge--security-#{safety_state}",
      options[:class]
    ].compact.join(' ')

    content_tag(:span, label, class: css_classes, title: badge_title(document, safety_state), **data_attrs)
  end

  def dsfr_file_link(document, **)
    safety_state = document_safety_state(document)

    if safety_state == 'unsafe'
      content_tag(:span,
        document.filename.to_s,
        title: 'Fichier bloqué pour raison de sécurité')
    else
      link_to(document.filename.to_s,
        url_for(document),
        target: '_blank',
        rel: 'noopener',
        class: 'file-link',
        **)
    end
  end

  private

  def badge_label_with_icon(safety_state)
    icon_classes = {
      'safe' => 'fr-icon-shield-fill',
      'unsafe' => 'fr-icon-warning-line',
      'scanning' => 'fr-icon-time-line'
    }

    label = I18n.t("malware_scan.label.#{safety_state}")
    icon_class = icon_classes[safety_state]

    return label unless icon_class

    icon = content_tag(:span, '', class: "#{icon_class} fr-icon--sm", 'aria-hidden': true)
    safe_join([icon, label])
  end

  def document_safety_state(document)
    blob = document.respond_to?(:blob) ? document.blob : document
    metadata = blob.metadata
    return 'scanning' unless metadata.key?('scan_safe')

    metadata['scan_safe'] == true ? 'safe' : 'unsafe'
  end

  def badge_title(document, safety_state)
    blob = document.respond_to?(:blob) ? document.blob : document

    case safety_state
    when 'safe'
      scanned_at = blob.metadata['scanned_at']
      date_str = scanned_at ? I18n.l(Time.zone.parse(scanned_at), format: :short) : 'récemment'
      "Fichier scanné et sécurisé le #{date_str}"
    when 'unsafe'
      'Ce fichier contient un virus ou un malware'
    when 'scanning'
      'Scan antivirus en cours...'
    end
  end
end
