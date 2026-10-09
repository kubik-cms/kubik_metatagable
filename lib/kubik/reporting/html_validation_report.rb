# frozen_string_literal: true

module Kubik
  module Reporting
    module HtmlValidationReport
      module_function

      def for(record)
        column = report_column
        return unknown_report unless column && record.respond_to?(column)

        raw_report = record.public_send(column)
        report = raw_report.is_a?(Hash) ? raw_report : {}
        findings = report["findings"] || report[:findings] || []
        checked_at = report["checked_at"] || report[:checked_at]
        return unknown_report if checked_at.blank? && findings.empty?

        status = status_for_findings(findings)
        {
          status: status,
          label: label_for(status),
          findings: findings,
          checked_at: report["checked_at"] || report[:checked_at]
        }
      end

      def status_for_findings(findings)
        AggregateStatus.from_findings(findings)
      end

      def report_column
        return unless defined?(KubikPublishable)

        KubikPublishable.config.html_quality_report_column
      end

      def unknown_report
        { status: :unknown, label: "Not checked", findings: [], checked_at: nil }
      end

      def label_for(status)
        {
          green: "OK",
          amber: "Warnings",
          red: "Issues",
          unknown: "Not checked"
        }[status] || status.to_s
      end
    end
  end
end
