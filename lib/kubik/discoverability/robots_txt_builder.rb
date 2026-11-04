# frozen_string_literal: true

module Kubik
  module Discoverability
    class RobotsTxtBuilder
      class << self
        def generate(settings)
          settings = SettingsStore.normalize(settings)
          lines = []
          policy = PolicyResolver.policy_hash(settings["crawler_policy"])
          matrix = policy["matrix"] || {}

          BotCatalog.entries(custom_bots: policy["custom_bots"]).each do |bot|
            discover = PolicyResolver.effective_stance(
              bot.token, axis: :discover, global_policy: policy
            )
            learn = PolicyResolver.effective_stance(
              bot.token, axis: :learn, global_policy: policy
            )
            next unless discover == :block || learn == :block

            lines << "User-agent: #{bot.token}"
            lines << "Disallow: /"
            lines << ""
          end

          if admin_paths_blocked?(settings)
            lines << "User-agent: *"
            lines << "Disallow: /admin/"
            lines << ""
          end

          custom_paths = Array(settings["robots_txt_extra_paths"]).map(&:to_s).reject(&:blank?)
          if custom_paths.any?
            lines << "User-agent: *"
            custom_paths.each { |path| lines << "Disallow: #{path}" }
            lines << ""
          end

          sitemap = settings["sitemap_url"].presence
          lines << "Sitemap: #{sitemap}" if sitemap

          lines.join("\n").strip + "\n"
        end

        private

        def admin_paths_blocked?(settings)
          value = settings["robots_block_admin_paths"]
          return true if value.nil?

          ActiveModel::Type::Boolean.new.cast(value)
        end
      end
    end
  end
end
