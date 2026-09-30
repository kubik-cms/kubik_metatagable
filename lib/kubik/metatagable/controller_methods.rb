# frozen_string_literal: true

module Kubik
  module Metatagable
    module ControllerMethods
      def insert_kubik_meta_tags(metatagable)
        @kubik_metatagable = metatagable
        meta_tags = metatagable.meta_tag || ::Kubik::MetaTag.new
        merged_title = KubikMetatagable.configuration.settings_class.instance.meta_tag.present? &&
                       KubikMetatagable.configuration.settings_class.instance.meta_tag[:site_name].present? ?
                        "#{meta_tags.title_tag} | #{KubikMetatagable.configuration.settings_class.instance.meta_tag[:site_name]}" :
                        meta_tags.title_tag
        @kubik_meta_override = {
          title_tag: merged_title,
          meta_description: meta_tags.meta_description,
          og_title: meta_tags.og_title,
          og_description: meta_tags.og_description,
          og_image: meta_tags.try(:og_image_upload).present? ? meta_tags.try(:og_image_upload).image_url : meta_tags.try(:og_image),
          og_url: request.original_url,
          twitter_title: meta_tags.twitter_title,
          twitter_description: meta_tags.twitter_description,
          twitter_image: meta_tags.try(:twitter_image_upload).present? ? meta_tags.twitter_image_upload.image_url : meta_tags.try(:twitter_media),
          twitter_card_type: meta_tags.twitter_card_type
        }
      end
    end
  end
end
