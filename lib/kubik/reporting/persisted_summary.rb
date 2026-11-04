# frozen_string_literal: true

module Kubik
  module Reporting
    module PersistedSummary
      module_function

      def for(record, host: nil)
        raw = Persistence.read_raw(record)
        checks_data = raw["checks"] || raw[:checks] || {}
        summary = {}

        Registry.checks_for(record).each do |check|
          entry = checks_data[check.key.to_s] || checks_data[check.key]
          summary[check.key] = if entry.present?
                                 Registry.normalize_result(entry)
                               else
                                 unknown_result
                               end
        end

        summary
      end

      def unknown_result
        { status: :unknown, label: "Not checked", findings: [], checked_at: nil }
      end
    end
  end
end
