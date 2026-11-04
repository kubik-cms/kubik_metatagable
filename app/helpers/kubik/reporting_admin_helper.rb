# frozen_string_literal: true

module Kubik
  module ReportingAdminHelper
    def self.summary_items(record = nil)
      Kubik::Reporting::Registry.ui_items(record)
    end

    def kubik_reporting_summary_items(record = nil)
      Kubik::Reporting::Registry.ui_items(record)
    end

    def kubik_reporting_summary(record, host: request.base_url)
      Kubik::Reporting.summary_for(record, host: host)
    end

    def kubik_reporting_check_report(record, key, host: request.base_url, refresh: false)
      return Kubik::Reporting::Registry.run_live_check(key, record, host: host) if refresh

      stored = Kubik::Reporting::Persistence.check(record, key)
      return stored if stored.present?

      { status: :unknown, label: "Not checked", findings: [], linters: [] }
    end

    def render_kubik_reporting_summary(record, host: request.base_url)
      render partial: "admin/kubik/content_resource_status_summary",
             locals: { record: record, variant: :compact, host: host }
    end

    def render_kubik_reporting_seo_reports(metatagable:, host: request.base_url)
      report = kubik_reporting_check_report(metatagable, :seo, host: host)
      render partial: "kubik/reporting/seo_reports_panel", locals: { report: report }
    end

    def kubik_reporting_indicator_href(item)
      "##{item[:anchor].presence || item[:tab_hash]}"
    end

    def kubik_reporting_summary_href(record, item)
      if item[:offcanvas_panel]
        kubik_reporting_offcanvas_panel_path(record, item[:offcanvas_panel])
      else
        kubik_reporting_indicator_href(item)
      end
    end

    def kubik_reporting_offcanvas_panel_path(record, panel_action)
      route_key = record.model_name.singular_route_key
      public_send("#{panel_action}_admin_#{route_key}_path", record)
    end

    def kubik_reporting_summary_offcanvas?(record, item)
      item[:offcanvas_panel].present? &&
        respond_to?(:kubik_html_quality_enabled?) &&
        kubik_html_quality_enabled?(record)
    end
  end
end
