# frozen_string_literal: true

module Kubik
  module ContentResourceAdminHelper
    # Override in host app when a record should skip reporting / preview panels (e.g. app-zone snippets).
    def kubik_content_resource_admin_insights_suppressed?(resource)
      resource.respond_to?(:managed_zone_page?) && resource.managed_zone_page?
    end

    def kubik_content_resource_checks_summary?(resource)
      return false if kubik_content_resource_admin_insights_suppressed?(resource)

      Kubik::ContentResourceAdmin.model_checks_summary?(resource.class)
    end

    def kubik_content_resource_preview_panel?(resource)
      return false if kubik_content_resource_admin_insights_suppressed?(resource)

      respond_to?(:kubik_preview_captures_show_panel?) && kubik_preview_captures_show_panel?(resource)
    end

    def kubik_content_resource_show_insights?(resource)
      kubik_content_resource_checks_summary?(resource) || kubik_content_resource_preview_panel?(resource)
    end

    def kubik_content_resource_preview_path_helper(resource)
      Kubik::ContentResourceAdmin.preview_path_helper_for(resource.class)
    end

    def kubik_content_resource_index_status?(resource)
      kubik_content_resource_publishable?(resource) || kubik_content_resource_checks_summary?(resource)
    end

    def kubik_content_resource_publishable?(resource)
      resource.class.respond_to?(:kubik_publishable_opts) && resource.class.kubik_publishable_opts.present?
    end

    def kubik_content_resource_published_index_status(resource)
      return nil unless kubik_content_resource_publishable?(resource)

      column = resource.class.kubik_publishable_opts[:column]
      published_at = resource.read_attribute(column)

      if resource.published?
        {
          status: :green,
          tooltip: "Published #{I18n.l(published_at, format: :long)}"
        }
      elsif published_at.present? && published_at > Time.current
        {
          status: :amber,
          tooltip: "Scheduled for #{I18n.l(published_at, format: :long)}"
        }
      else
        {
          status: :unpublished,
          tooltip: "Unpublished"
        }
      end
    end

    def kubik_content_resource_index_reporting_summary(resource)
      return {} unless kubik_content_resource_checks_summary?(resource)

      Kubik::Reporting.summary_for(resource, host: request.base_url)
    end

    def kubik_content_resource_reporting_issues_count(result)
      status = (result[:status] || result["status"] || :unknown).to_sym
      return nil if status == :unknown

      Array(result[:findings] || result["findings"]).size
    end

    def kubik_content_resource_reporting_index_tooltip(category_label, result)
      findings = Array(result[:findings] || result["findings"])
      status = (result[:status] || result["status"] || :unknown).to_sym
      count = kubik_content_resource_reporting_issues_count(result)

      base = if status == :unknown
               "#{category_label}: Not checked"
             elsif findings.empty?
               "#{category_label}: OK"
             else
               "#{category_label}: #{findings.size} issue#{'s' if findings.size != 1}"
             end

      base = "#{base} (#{count})" unless count.nil?

      detail = kubik_content_resource_reporting_detail_text(result)
      return base if detail.blank? || detail == "Not checked yet."

      "#{base}\n#{detail}"
    end

    def kubik_content_resource_reporting_detail_text(result)
      status = (result[:status] || result["status"] || :unknown).to_sym
      return "Not checked yet." if status == :unknown

      summary_label = result[:label] || result["label"]
      findings = Array(result[:findings] || result["findings"])
      messages = findings.filter_map { |finding| finding[:message] || finding["message"] }.uniq
      count = kubik_content_resource_reporting_issues_count(result)

      detail = if messages.any?
                   [summary_label, messages.join(" · ")].compact.join(" — ")
                 else
                   summary_label.presence || "No issues found."
                 end

      count.nil? ? detail : detail
    end

    def kubik_content_resource_reporting_label_with_count(label, result)
      count = kubik_content_resource_reporting_issues_count(result)
      count.nil? ? label : "#{label} (#{count})"
    end

    def kubik_content_resource_reporting_summary_link_label(label, result)
      text = kubik_content_resource_reporting_label_with_count(label, result)
      status = (result[:status] || result["status"] || :unknown).to_sym
      summary = result[:label] || result["label"]
      return text if status == :unknown || status == :green || summary.blank?

      "#{text} — #{summary}"
    end

    def kubik_content_resource_publishing_detail_text(resource)
      return nil unless kubik_content_resource_publishable?(resource)

      column = resource.class.kubik_publishable_opts[:column]
      published_at = resource.read_attribute(column)

      if resource.published?
        "Live on the public site — published #{I18n.l(published_at, format: :long)}."
      elsif published_at.present? && published_at > Time.current
        "Scheduled — will go live #{I18n.l(published_at, format: :long)}."
      else
        "Not visible on the public site until you set a publish date."
      end
    end

    def render_kubik_content_resource_details_status(record)
      render partial: "admin/kubik/content_resource_details_status", locals: { record: record }
    end

    def kubik_content_resource_index_status_href(record, item)
      if item[:offcanvas_panel] && kubik_content_resource_index_html_offcanvas?(record)
        kubik_reporting_offcanvas_panel_path(record, item[:offcanvas_panel])
      else
        admin_show_path = public_send("admin_#{record.model_name.singular_route_key}_path", record)
        anchor = item[:anchor].presence || item[:tab_hash]
        anchor.present? ? "#{admin_show_path}##{anchor}" : admin_show_path
      end
    end

    def kubik_html_quality_enabled?(record)
      return false unless defined?(Kubik::Features)

      Kubik::Features.html_quality_enabled_for_model?(record)
    end

    def kubik_content_resource_index_html_offcanvas?(record)
      kubik_html_quality_enabled?(record)
    end

    def kubik_content_resource_index_status_offcanvas?(record, item)
      item[:offcanvas_panel].present? && kubik_content_resource_index_html_offcanvas?(record)
    end

    def render_kubik_content_resource_index_status(record)
      render partial: "admin/kubik/content_resource_index_status", locals: { record: record }
    end

    def render_kubik_content_resource_status_summary(record, variant: :detailed)
      render partial: "admin/kubik/content_resource_status_summary",
             locals: { record: record, variant: variant, host: request.base_url }
    end

    # Backwards compatibility with host apps that used managed_zone naming.
    alias kubik_content_resource_managed_zone_page? kubik_content_resource_admin_insights_suppressed?
  end
end

module Admin
  module ContentResourceHelper
    include Kubik::ContentResourceAdminHelper
  end
end
