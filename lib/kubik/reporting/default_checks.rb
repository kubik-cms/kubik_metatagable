# frozen_string_literal: true

module Kubik
  module Reporting
    module DefaultChecks
      module_function

      def register!
        register_seo!
        register_sharing!
        register_html_validation! if defined?(KubikPublishable)
      end

      def register_seo!
        Registry.register(
          :seo,
          label: "SEO",
          ui: { tab_hash: "seo", anchor: "seo" },
          available: ->(record) { metatagable?(record) }
        ) do |record, host:|
          SeoReport.for(record, host: host)
        end
      end

      def register_sharing!
        Registry.register(
          :sharing,
          label: "Sharing",
          ui: { tab_hash: "social-media", anchor: "social-media" },
          available: ->(record) { metatagable?(record) }
        ) do |record, host:|
          SharingReport.for(record, host: host)
        end
      end

      def register_geo!
        Registry.register(
          :geo,
          label: "GEO",
          ui: { tab_hash: "geo", anchor: "geo" },
          available: ->(record) { metatagable?(record) }
        ) do |record, host:|
          GeoReport.for(record, host: host)
        end
      end

      def register_html_validation!
        Registry.register(
          :html_validation,
          label: "HTML validity",
          ui: { offcanvas_panel: :html_quality_panel },
          available: ->(record) { html_quality_available?(record) }
        ) do |record, host:|
          _host = host # render uses configured renderer, not host
          raw = Kubik::HtmlQuality.run!(record)
          HtmlValidationReport.from_raw(raw)
        end
      end

      def metatagable?(record)
        defined?(Kubik::Metatagable) &&
          record.class.included_modules.include?(Kubik::Metatagable)
      end

      def html_quality_available?(record)
        return false unless defined?(KubikPublishable)
        return false unless KubikPublishable.config.html_quality_supported?(record.class.name)

        if defined?(Kubik::Features) && Kubik::Features.respond_to?(:html_quality_enabled_for_model?)
          return Kubik::Features.html_quality_enabled_for_model?(record)
        end

        true
      end
    end
  end
end
