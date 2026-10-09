# frozen_string_literal: true

module Kubik
  module Reporting
    module AggregateStatus
      module_function

      # Red when any error-level finding exists; amber when only warnings; green when clean.
      def from_findings(findings)
        list = Array(findings)
        return :green if list.empty?

        severities = list.map { |finding| severity_for(finding) }
        return :red if severities.include?(:error)
        return :amber if severities.include?(:warning)

        :green
      end

      def severity_for(finding)
        raw = (finding["severity"] || finding[:severity]).to_s.downcase
        return :error if raw == "error"
        return :warning if raw.in?(%w[warning warn])

        code = (finding["code"] || finding[:code]).to_s
        return :error if code == "render_failed"

        :warning
      end
    end
  end
end
