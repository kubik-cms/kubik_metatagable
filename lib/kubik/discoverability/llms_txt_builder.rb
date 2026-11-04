# frozen_string_literal: true

module Kubik
  module Discoverability
    class LlmsTxtBuilder
      class << self
        def render(settings)
          settings = SettingsStore.normalize(settings)
          parts = []
          parts << settings["llms_txt_body"].to_s.strip if settings["llms_txt_body"].present?

          if include_policy_summary?(settings)
            summary = PolicyResolver.policy_summary(settings: settings)
            if summary.present?
              parts << "## Crawler policy"
              parts << summary
            end
          end

          site_title = settings["site_title"].presence || settings["site_name"].presence
          if parts.empty? && site_title.present?
            parts << "# #{site_title}"
            parts << ""
            parts << "> Site crawler and AI usage policy is configured in site settings."
          end

          parts.join("\n\n").strip + "\n"
        end

        private

        def include_policy_summary?(settings)
          value = settings["llms_txt_include_policy_summary"]
          return true if value.nil?

          ActiveModel::Type::Boolean.new.cast(value)
        end
      end
    end
  end
end
