# frozen_string_literal: true

module Kubik
  module ReportingAdminHelper
    SUMMARY_ITEMS = [
      { key: :html_validation, label: "HTML validity", offcanvas_panel: :html_quality_panel },
      { key: :seo, label: "SEO", tab_hash: "seo", anchor: "seo-reports" },
      { key: :sharing, label: "Sharing", tab_hash: "social", anchor: "social" }
    ].freeze

    def kubik_reporting_summary(record, host: request.base_url)
      Kubik::Reporting.summary_for(record, host: host)
    end

    def render_kubik_reporting_summary(record, host: request.base_url)
      summary = kubik_reporting_summary(record, host: host)
      render partial: "kubik/reporting/summary_indicators",
             locals: { summary: summary, record: record }
    end

    def render_kubik_reporting_seo_reports(metatagable:, host: request.base_url)
      report = Kubik::Reporting::SeoReport.for(metatagable, host: host)
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

    def kubik_reporting_summary_offcanvas?(item)
      item[:offcanvas_panel].present?
    end
  end
end
