# frozen_string_literal: true

namespace :kubik_metatagable do
  desc "Backfill kubik_meta_tags OG/Twitter copy from SEO fields (IMPORTER_DRY_RUN=1)"
  task backfill_social_meta: :environment do
    dry = ENV["IMPORTER_DRY_RUN"].present?
    result = Kubik::Metatagable::SocialMetaBackfill.backfill!(dry_run: dry)
    puts "kubik_metatagable:backfill_social_meta #{dry ? '(dry run)' : ''} " \
         "updated=#{result[:updated]} skipped=#{result[:skipped]}"
  end
end
