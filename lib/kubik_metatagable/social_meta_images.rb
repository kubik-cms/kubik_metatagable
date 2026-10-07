# frozen_string_literal: true

module KubikMetatagable
  # Builds absolute URLs for Open Graph / Twitter images (Shrine uploads or paths).
  module SocialMetaImages
    DEFAULT_DERIVATIVE = :social_og
    TWITTER_SUMMARY_DERIVATIVE = :social_twitter_small
    TWITTER_LARGE_DERIVATIVE = :social_twitter_large

    module_function

    def derivative_for(platform:, meta_tag: nil)
      override = KubikMetatagable.configuration.social_image_derivative
      return override if override.present?

      case platform.to_sym
      when :twitter
        meta_tag&.twitter_card_type.to_s == "summary" ? TWITTER_SUMMARY_DERIVATIVE : TWITTER_LARGE_DERIVATIVE
      when :og, :facebook, :linkedin
        DEFAULT_DERIVATIVE
      else
        DEFAULT_DERIVATIVE
      end
    end

    def image_url(upload, host:, derivative: nil, platform: nil, meta_tag: nil)
      return unless upload.present?

      derivative ||= derivative_for(platform: platform || :og, meta_tag: meta_tag)
      absolute_url(upload.image_url(derivative, host: host), host: host)
    end

    def absolute_url(url, host:)
      return if url.blank?
      return url if url.match?(%r{\Ahttps?://})

      path = url.start_with?("/") ? url : "/#{url}"
      "#{host.to_s.chomp('/')}#{path}"
    end
  end
end
