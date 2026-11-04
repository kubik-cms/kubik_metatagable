# frozen_string_literal: true

module Kubik
  module Reporting
    module Runner
      module_function

      def run!(record, host:)
        host = resolve_host(host)
        checks = {}
        Registry.checks_for(record).each do |check|
          result = Registry.normalize_result(check.run.call(record, host: host))
          checks[check.key.to_s] = result.deep_stringify_keys
        end

        payload = {
          checked_at: Time.current.iso8601,
          host: host,
          checks: checks
        }

        if Persistence.supported?(record)
          Persistence.write!(record, payload)
        elsif defined?(KubikPublishable)
          sync_html_only(record, checks)
        end

        payload.deep_symbolize_keys
      end

      def resolve_host(host)
        configured = KubikMetatagable.configuration.content_checks_default_host
        configured = configured.call if configured.respond_to?(:call)
        host.presence || configured.presence || ENV.fetch("KUBIK_CONTENT_CHECKS_HOST", "http://localhost:3000")
      end

      def sync_html_only(record, checks)
        html = checks["html_validation"]
        return if html.blank?

        column = KubikPublishable.config.html_quality_report_column
        return unless column && record.class.column_names.include?(column.to_s)

        findings = html["findings"] || []
        record.update_column(
          column,
          {
            "checked_at" => html["checked_at"],
            "findings" => findings,
            "summary" => { "warnings" => findings.size }
          }
        )
      end
    end
  end
end
