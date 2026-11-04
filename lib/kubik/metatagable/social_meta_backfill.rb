# frozen_string_literal: true

module Kubik
  module Metatagable
    # Persists social Open Graph / Twitter fields from SEO columns (Slickr never stored
    # og:type or twitter:card on slickr_meta_tags; Kubik admin expects them on kubik_meta_tags).
    class SocialMetaBackfill
      TWITTER_CARD_DEFAULT = "summary_large_image"

      class << self
        def backfill!(scope: nil, dry_run: false)
          scope ||= Kubik::MetaTag.all
          updated = 0
          skipped = 0

          scope.find_each do |meta_tag|
            if backfill_record!(meta_tag, dry_run: dry_run)
              updated += 1
            else
              skipped += 1
            end
          end

          result = { updated: updated, skipped: skipped }
          Rails.logger.info "[kubik_metatagable] social_meta_backfill done: #{result.inspect}"
          result
        end

        def backfill_record!(meta_tag, dry_run: false)
          record = meta_tag.metatagable
          return false unless record

          attrs = attributes_to_apply(meta_tag, record)
          return false if attrs.empty?

          if dry_run
            Rails.logger.info(
              "[kubik_metatagable] dry-run social_meta_backfill meta_tag=#{meta_tag.id} " \
              "#{record.class.name}##{record.id} fields=#{attrs.keys.join(', ')}"
            )
            return true
          end

          meta_tag.update!(attrs)
          true
        end

        def attributes_to_apply(meta_tag, record)
          config = KubikMetatagable.configuration
          updates = {}

          title = meta_tag.title_tag.presence || default_title(record)
          description = meta_tag.meta_description.presence || default_description(record)
          og_description = meta_tag.og_description.presence || description

          if meta_tag.og_title.blank? && title.present?
            updates[:og_title] = title
          end

          if meta_tag.og_description.blank? && og_description.present?
            updates[:og_description] = og_description
          end

          resolved_og_title = updates[:og_title] || meta_tag.og_title.presence || title
          if meta_tag.twitter_title.blank? && resolved_og_title.present?
            updates[:twitter_title] = resolved_og_title
          end

          resolved_og_description = updates[:og_description] || meta_tag.og_description.presence || og_description
          if meta_tag.twitter_description.blank? && resolved_og_description.present?
            updates[:twitter_description] = resolved_og_description
          end

          if meta_tag.og_type.blank?
            updates[:og_type] = config.default_og_type_for(record)
          end

          if meta_tag.twitter_card_type.blank?
            updates[:twitter_card_type] = TWITTER_CARD_DEFAULT
          end

          updates
        end

        private

        def default_title(record)
          if record.respond_to?(:title)
            record.title
          elsif record.respond_to?(:name)
            record.name
          else
            ""
          end
        end

        def default_description(record)
          if record.respond_to?(:listing_summary)
            record.listing_summary
          elsif record.respond_to?(:description)
            record.description
          else
            ""
          end
        end
      end
    end
  end
end
