# frozen_string_literal: true

module Kubik
  module Metatagable
    module ControllerMethods
      def insert_kubik_meta_tags(metatagable)
        @kubik_metatagable = metatagable
        meta_tags = metatagable.meta_tag || ::Kubik::MetaTag.new
        settings_meta = KubikMetatagable.configuration.settings_class.instance.meta_tag
        site_name = settings_meta.try(:site_name).presence || settings_meta.try(:[], :site_name)
        merged_title =
          if site_name.present?
            "#{meta_tags.title_tag} | #{site_name}"
          else
            meta_tags.title_tag
          end

        host = request.base_url.chomp("/")
        resolved = Kubik::Metatagable::SocialMetaResolver.resolve(metatagable, host: host)

        @kubik_meta_override = {
          title_tag: merged_title,
          meta_description: resolved[:meta_description],
          og_title: resolved[:og_title],
          og_description: resolved[:og_description],
          og_type: resolved[:og_type],
          og_image: resolved[:og_image],
          og_url: request.original_url,
          twitter_title: resolved[:twitter_title],
          twitter_description: resolved[:twitter_description],
          twitter_image: resolved[:twitter_image],
          twitter_card_type: resolved[:twitter_card_type]
        }
      end
    end
  end
end
