# frozen_string_literal: true

module Kubik
  module Discoverability
    class PolicyResolver
      class << self
        def normalize_stance(value)
          key = value.to_s.strip.downcase
          return :inherit if key.blank? || key == "inherit"
          return :allow if key == "allow"
          return :block if key == "block"

          :inherit
        end

        def effective_stance(token, axis:, global_policy: {}, resource_policy: {}, record: nil)
          token = token.to_s
          record_stance = record_stance_for(token, axis, record)
          return record_stance unless record_stance == :inherit

          resource_stance = matrix_stance(resource_policy, token, axis)
          return resource_stance unless resource_stance == :inherit

          global_stance = matrix_stance(global_policy, token, axis)
          return global_stance unless global_stance == :inherit

          bot = BotCatalog.find(token)
          return bot.public_send("default_#{axis}") if bot

          :inherit
        end

        def meta_directives_for(record: nil, resource_key: nil)
          directives = []
          meta = record&.meta_tag

          if meta&.respond_to?(:robots_noindex) && meta.robots_noindex?
            directives << "noindex"
          end
          if meta&.respond_to?(:robots_nofollow) && meta.robots_nofollow?
            directives << "nofollow"
          end
          if meta&.respond_to?(:robots_noarchive) && meta.robots_noarchive?
            directives << "noarchive"
          end
          if meta&.respond_to?(:robots_nosnippet) && meta.robots_nosnippet?
            directives << "nosnippet"
          end

          directives += %w[noai noimageai] if record_level_learn_blocked?(record)

          directives.uniq
        end

        def policy_hash(raw)
          (raw || {}).with_indifferent_access
        end

        def policy_summary(settings: nil)
          settings ||= SettingsStore.current
          global = policy_hash(settings["crawler_policy"])
          lines = []
          BotCatalog.entries(custom_bots: global["custom_bots"]).each do |bot|
            discover = effective_stance(
              bot.token, axis: :discover, global_policy: global, resource_policy: {}
            )
            learn = effective_stance(
              bot.token, axis: :learn, global_policy: global, resource_policy: {}
            )
            next if discover == :inherit && learn == :inherit

            lines << "- #{bot.label} (#{bot.token}): discover=#{discover}, learn=#{learn}"
          end
          lines.join("\n")
        end

        private

        def matrix_stance(policy, token, axis)
          matrix = policy_hash(policy)["matrix"] || {}
          row = (matrix[token] || matrix[token.to_s] || {}).with_indifferent_access
          normalize_stance(row[axis])
        end

        def record_stance_for(_token, axis, record)
          meta = record&.meta_tag
          return :inherit unless meta

          if axis == :discover
            return :block if meta.respond_to?(:robots_noindex) && meta.robots_noindex?
          elsif axis == :learn
            return :block if meta.respond_to?(:block_ai_crawlers) && meta.block_ai_crawlers?
          end
          :inherit
        end

        def record_level_learn_blocked?(record)
          meta = record&.meta_tag
          meta&.respond_to?(:block_ai_crawlers) && meta.block_ai_crawlers?
        end

        def resource_policy_for(resource_key)
          return {} unless resource_key.present? && defined?(KubikSettings::ResourceResolver)
          return {} unless KubikSettings::ResourceResolver.registered?(resource_key)

          KubikSettings::ResourceResolver.get(resource_key, :crawler_policy) || {}
        rescue StandardError
          {}
        end
      end
    end
  end
end
