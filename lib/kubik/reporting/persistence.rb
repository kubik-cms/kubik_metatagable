# frozen_string_literal: true

module Kubik
  module Reporting
    module Persistence
      module_function

      def report_model
        KubikMetatagable.configuration.content_checks_report_model.constantize
      end

      def supported?(record)
        return false unless report_model.table_available?
        return false unless record.respond_to?(:kubik_content_checks_report)

        record.class.kubik_content_checks_enabled?
      end

      def read_raw(record)
        if record.respond_to?(:kubik_content_checks_report)
          report = record.kubik_content_checks_report
          if report
            payload = report.report
            return payload.deep_stringify_keys if payload.is_a?(Hash) && payload.present?
          end
        end

        legacy_column_payload(record)
      end

      def stored?(record)
        read_raw(record).present?
      end

      def check(record, key)
        checks = read_raw(record)["checks"] || read_raw(record)[:checks] || {}
        entry = checks[key.to_s] || checks[key.to_sym]
        entry.is_a?(Hash) ? Registry.normalize_result(entry) : nil
      end

      def write!(record, payload)
        data = payload.deep_stringify_keys

        if supported?(record)
          report = record.kubik_content_checks_report || record.build_kubik_content_checks_report
          report.report = data
          report.save!
          sync_html_quality_column(record, data)
        elsif legacy_column_supported?(record)
          column = legacy_report_column
          record.update_column(column, data)
          sync_html_quality_column(record, data)
        else
          raise ArgumentError, "content checks persistence is not configured for #{record.class.name}"
        end

        data
      end

      def legacy_report_column
        KubikMetatagable.configuration.content_checks_legacy_report_column
      end

      def legacy_column_supported?(record)
        column = legacy_report_column
        return false if column.blank?

        record.class.column_names.include?(column.to_s)
      end

      def legacy_column_payload(record)
        return {} unless legacy_column_supported?(record)

        raw = record.public_send(legacy_report_column)
        raw.is_a?(Hash) ? raw : {}
      end

      def sync_html_quality_column(record, payload)
        return unless defined?(KubikPublishable)

        html_column = KubikPublishable.config.html_quality_report_column
        return unless html_column && record.class.column_names.include?(html_column.to_s)

        checks = payload["checks"] || {}
        html_check = checks["html_validation"]
        return if html_check.blank?

        findings = html_check["findings"] || []
        record.update_column(
          html_column,
          {
            "checked_at" => html_check["checked_at"] || payload["checked_at"],
            "findings" => findings,
            "summary" => { "warnings" => findings.size }
          }
        )
      end
    end
  end
end
