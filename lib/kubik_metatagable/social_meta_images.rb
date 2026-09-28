# frozen_string_literal: true

module KubikMetatagable
  # Builds absolute URLs for Open Graph / Twitter images (Shrine uploads or paths).
  module SocialMetaImages
    DEFAULT_DERIVATIVE = :content_1200

    module_function

    def image_url(upload, host:, derivative: DEFAULT_DERIVATIVE)
      return unless upload.present?

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
