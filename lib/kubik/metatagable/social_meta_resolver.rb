# frozen_string_literal: true

module Kubik
  module Metatagable
    class SocialMetaResolver
      def self.resolve(record, host:)
        new(record, host: host).resolve
      end

      def initialize(record, host:)
        @record = record
        @host = host.to_s.chomp("/")
        @config = KubikMetatagable.configuration
      end

      def resolve
        meta_tag = @record.meta_tag
        site_meta = site_meta_data

        title_tag = meta_tag.title_tag.presence || default_title
        site_name = site_meta[:site_title].presence || site_meta["site_title"]
        merged_title = if site_name.present?
                           "#{title_tag} | #{site_name}"
                         else
                           title_tag
                         end

        og_image = social_image(meta_tag, :og)
        twitter_image = social_image(meta_tag, :twitter)

        {
          title_tag: merged_title,
          meta_description: meta_tag.meta_description.presence || default_description,
          og_title: meta_tag.og_title.presence || title_tag,
          og_description: meta_tag.og_description.presence || meta_tag.meta_description.presence || default_description,
          og_image: og_image,
          og_url: canonical_url,
          og_type: meta_tag.og_type.presence || @config.default_og_type_for(@record),
          twitter_card_type: meta_tag.twitter_card_type.presence || "summary_large_image",
          twitter_title: meta_tag.twitter_title.presence || meta_tag.og_title.presence || title_tag,
          twitter_description: meta_tag.twitter_description.presence || meta_tag.og_description.presence || default_description,
          twitter_image: twitter_image
        }
      end

      private

      def site_meta_data
        settings_class = @config.settings_class
        if settings_class.present?
          settings_class.instance.meta_tag.attributes.symbolize_keys
        else
          {}
        end
      rescue StandardError
        {}
      end

      def social_image(meta_tag, platform)
        upload = platform == :twitter ? meta_tag.twitter_image_upload : meta_tag.og_image_upload
        if upload.present?
          KubikMetatagable::SocialMetaImages.image_url(
            upload,
            host: @host,
            derivative: @config.social_image_derivative
          )
        else
          raw = platform == :twitter ? meta_tag.twitter_media : meta_tag.og_image
          KubikMetatagable::SocialMetaImages.absolute_url(raw, host: @host)
        end
      end

      def default_title
        if @record.respond_to?(:title)
          @record.title
        elsif @record.respond_to?(:name)
          @record.name
        else
          ""
        end
      end

      def default_description
        if @record.respond_to?(:listing_summary)
          @record.listing_summary
        elsif @record.respond_to?(:description)
          @record.description
        else
          ""
        end
      end

      def canonical_url
        routes = Rails.application.routes.url_helpers
        path = @config.canonical_path_for(@record, routes)
        "#{@host}#{path}"
      end
    end
  end
end
