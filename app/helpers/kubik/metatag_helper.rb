# frozen_string_literal: true

module Kubik
  module MetatagHelper
    def kubik_page_title
      [kubik_meta_data(:title_tag), @kubik_settings.try(:[], "site_title")]
        .reject(&:blank?)
        .join(@kubik_settings.try(:[], "site_title_separator") || "|")
    end

    def kubik_meta_data(attr)
      meta = kubik_site_meta_data.symbolize_keys.merge(compact_override)
      meta[attr]
    end

    def kubik_share_data
      {
        title: kubik_meta_data(:og_title).presence || kubik_page_title,
        text: kubik_meta_data(:og_description).presence || kubik_meta_data(:meta_description),
        url: kubik_meta_data(:og_url).presence || request.original_url
      }.compact
    end

    def kubik_share_button(variant: :footer, button_class: nil, share_data: nil, **locals)
      render(
        partial: "kubik/metatagable/share_button",
        locals: {
          variant: variant,
          button_class: button_class,
          share_data: share_data || kubik_share_data,
          **locals
        }
      )
    end

    def kubik_site_meta_data
      @kubik_site_meta_data ||=
        if KubikMetatagable.configuration.settings_class.present?
          settings = KubikMetatagable.configuration.settings_class.instance.meta_tag.attributes
          settings.merge(get_social_uploads(KubikMetatagable.configuration.settings_class.instance.meta_tag)) if defined?(Kubik::Uploadable)
        else
          settings = ::Kubik::MetaTag.new.attributes
          settings.merge(get_social_uploads(::Kubik::MetaTag.new)) if defined?(Kubik::Uploadable)
        end
      @kubik_site_meta_data
    end

    private

    def get_social_uploads(meta_tag)
      {
        og_image: meta_tag.og_image_upload.try(:image_url),
        twitter_image: meta_tag.twitter_image_upload.try(:image_url)
      }
    end

    def compact_override
      override = @kubik_meta_override || {}
      override.select do |_, value|
        value.present?
      end
    end
  end
end
