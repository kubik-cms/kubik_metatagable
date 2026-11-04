# frozen_string_literal: true

require "kubik/metatagable/geo_reporting/document_geo_checks"
require "kubik/metatagable/geo_reporting/geo_report"

module Kubik
  module Reporting
    DefaultChecks.register_geo!
  end

  module ReportingAdminHelper
    def render_kubik_reporting_geo_reports(metatagable:, host: request.base_url)
      report = kubik_reporting_check_report(metatagable, :geo, host: host) ||
               Kubik::Reporting::GeoReport.for(metatagable, host: host)
      render partial: "kubik/geo_reporting/geo_reports_panel", locals: { report: report }
    end
  end
end
