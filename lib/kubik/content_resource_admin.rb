# frozen_string_literal: true

module Kubik
  # Introspects Kubik model concerns to drive Active Admin content-resource UI.
  module ContentResourceAdmin
    module_function

    def model_previewable?(klass)
      klass.respond_to?(:kubik_previewable_opts) &&
        klass.kubik_previewable_opts &&
        ActiveModel::Type::Boolean.new.cast(klass.kubik_previewable_opts[:preview_enabled])
    end

    def model_preview_captures?(klass)
      klass.respond_to?(:kubik_preview_screenshots_configured?) &&
        klass.kubik_preview_screenshots_configured?
    end

    def model_html_quality?(klass)
      defined?(Kubik::HtmlQualityCheckable) &&
        klass.included_modules.include?(Kubik::HtmlQualityCheckable)
    end

    def model_publishable?(klass)
      klass.respond_to?(:kubik_publishable_opts) && klass.kubik_publishable_opts.present?
    end

    def model_versionable?(klass)
      defined?(Kubik::Versionable) && klass.included_modules.include?(Kubik::Versionable)
    end

    def model_metatagable?(klass)
      defined?(Kubik::Metatagable) && klass.included_modules.include?(Kubik::Metatagable)
    end

    def model_checks_summary?(klass)
      model_metatagable?(klass) || model_html_quality?(klass)
    end

    def preview_path_helper_for(klass)
      return nil unless model_previewable?(klass)

      route_key = klass.model_name.singular_route_key
      :"preview_#{route_key}_admin_#{route_key}_path"
    end

    class << self
      attr_accessor :preview_html_renderer, :content_versions_enabled

      def content_versions_enabled?
        flag = content_versions_enabled
        return flag.call if flag.respond_to?(:call)
        return flag unless flag.nil?

        defined?(Kubik::ContentVersionAdminSupport)
      end
    end
  end
end
