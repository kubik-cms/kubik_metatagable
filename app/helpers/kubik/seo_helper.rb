# frozen_string_literal: true

module Kubik
  module SeoHelper
    def kubik_share_enabled?
      meta_tag = kubik_current_meta_tag
      return true if meta_tag.nil?

      meta_tag.share_enabled?
    end

    def kubik_robots_meta_content
      kubik_current_meta_tag&.robots_meta_content
    end

    def kubik_canonical_href
      meta_tag = kubik_current_meta_tag
      override = meta_tag&.canonical_url_override.presence
      return override if override

      method_name = KubikMetatagable.configuration.canonical_url_method
      if method_name.present? && respond_to?(method_name)
        return public_send(method_name)
      end

      record = @kubik_metatagable
      return nil unless record

      routes = Rails.application.routes.url_helpers
      path = KubikMetatagable.configuration.canonical_path_for(record, routes)
      "#{request.base_url.chomp('/')}" + path
    end

    private

    def kubik_current_meta_tag
      @kubik_metatagable&.meta_tag
    end
  end
end
