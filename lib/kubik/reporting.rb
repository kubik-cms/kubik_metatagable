# frozen_string_literal: true

module Kubik
  module Reporting
    STATUSES = %i[green amber red unknown].freeze

    module_function

    def summary_for(record, host:)
      if Persistence.supported?(record)
        PersistedSummary.for(record, host: host)
      else
        summary_for_live(record, host: host)
      end
    end

    def summary_for_live(record, host:)
      summary = {}
      Registry.checks_for(record).each do |check|
        summary[check.key] = Registry.run_live_check(check.key, record, host: host)
      end
      summary
    end
  end
end

require "kubik/reporting/registry"
require "kubik/reporting/persistence"
require "kubik/reporting/persisted_summary"
require "kubik/reporting/runner"
require "kubik/reporting/default_checks"
require "kubik/reporting/aggregate_status"
require "kubik/reporting/rendered_document"
require "kubik/reporting/link_checker"
require "kubik/reporting/document_seo_checks"
require "kubik/reporting/html_validation_report"
require "kubik/reporting/seo_report"
require "kubik/reporting/sharing_report"

Kubik::Reporting::DefaultChecks.register!
