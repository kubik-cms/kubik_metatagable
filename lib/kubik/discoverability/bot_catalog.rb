# frozen_string_literal: true

require "ai_crawler_index"

module Kubik
  module Discoverability
    class BotCatalog
      Entry = Struct.new(
        :token, :label, :operator, :category, :category_label, :docs_url,
        :default_discover, :default_learn,
        keyword_init: true
      )

      class << self
        def entries(custom_bots: [])
          from_index + normalize_custom(custom_bots)
        end

        def version
          Gem.loaded_specs["ai-crawler-index"]&.version&.to_s || "unknown"
        end

        def find(token)
          entries.find { |e| e.token == token.to_s }
        end

        private

        def from_index
          AiCrawlerIndex.list.map { |row| entry_from_index(row) }
        end

        def entry_from_index(row)
          category = row["category"].to_s
          Entry.new(
            token: row["robots_token"].presence || row["name"],
            label: row["name"],
            operator: row["operator"],
            category: category,
            category_label: row["category_label"],
            docs_url: row["docs"],
            default_discover: Discoverability.configuration.default_for(category, :discover),
            default_learn: Discoverability.configuration.default_for(category, :learn)
          )
        end

        def normalize_custom(custom_bots)
          Array(custom_bots).filter_map do |bot|
            bot = bot.with_indifferent_access
            token = bot[:token].presence || bot[:robots_token].presence
            next if token.blank?

            Entry.new(
              token: token,
              label: bot[:label].presence || token,
              operator: bot[:operator],
              category: bot[:category].presence || "tool",
              category_label: bot[:category_label],
              docs_url: bot[:docs_url],
              default_discover: stance_or_default(bot[:default_discover], bot[:category], :discover),
              default_learn: stance_or_default(bot[:default_learn], bot[:category], :learn)
            )
          end
        end

        def stance_or_default(value, category, axis)
          resolved = PolicyResolver.normalize_stance(value)
          return resolved unless resolved == :inherit

          Discoverability.configuration.default_for(category, axis)
        end
      end
    end
  end
end
