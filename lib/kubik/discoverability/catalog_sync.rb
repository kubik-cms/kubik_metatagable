# frozen_string_literal: true

require "json"
require "net/http"

module Kubik
  module Discoverability
    class CatalogSync
      LIVE_AGENTS_URL = "https://www.pathwren.workers.dev/data/agents.json"

      class << self
        def diff_against_bundled
          live = fetch_live_crawlers
          bundled_tokens = BotCatalog.entries.map(&:token).to_set
          live_tokens = live.map { |c| c["robots_token"].presence || c["name"] }.compact.to_set
          new_tokens = (live_tokens - bundled_tokens).to_a.sort
          {
            source: LIVE_AGENTS_URL,
            fetched_at: Time.current.iso8601,
            bundled_version: BotCatalog.version,
            new_tokens: new_tokens,
            new_count: new_tokens.size
          }
        end

        def fetch_live_crawlers
          uri = URI(LIVE_AGENTS_URL)
          response = Net::HTTP.get_response(uri)
          raise Error, "Catalog sync failed: HTTP #{response.code}" unless response.is_a?(Net::HTTPSuccess)

          payload = JSON.parse(response.body)
          Array(payload["crawlers"] || payload)
        rescue JSON::ParserError => e
          raise Error, "Catalog sync invalid JSON: #{e.message}"
        end
      end
    end
  end
end
