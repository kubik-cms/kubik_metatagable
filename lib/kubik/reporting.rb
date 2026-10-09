# frozen_string_literal: true

module Kubik
  module Reporting
    STATUSES = %i[green amber red unknown].freeze

    module_function

    def summary_for(record, host:)
      {
        html_validation: HtmlValidationReport.for(record),
        seo: SeoReport.for(record, host: host),
        sharing: SharingReport.for(record, host: host)
      }
    end
  end
end

require "kubik/reporting/aggregate_status"
require "kubik/reporting/rendered_document"
require "kubik/reporting/link_checker"
require "kubik/reporting/document_seo_checks"
require "kubik/reporting/html_validation_report"
require "kubik/reporting/seo_report"
require "kubik/reporting/sharing_report"
