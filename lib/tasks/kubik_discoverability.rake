# frozen_string_literal: true

namespace :kubik do
  namespace :discoverability do
    desc "Diff live AI Crawler Index against bundled ai-crawler-index gem"
    task catalog_diff: :environment do
      diff = Kubik::Discoverability::CatalogSync.diff_against_bundled
      puts "Bundled version: #{diff[:bundled_version]}"
      puts "New tokens (#{diff[:new_count]}): #{diff[:new_tokens].join(', ')}"
    end
  end
end
