# frozen_string_literal: true

module Kubik
  module Reporting
    class SharingReport
      OG_REQUIRED = %w[og:title og:description og:url og:type].freeze
      TWITTER_REQUIRED = %w[twitter:card twitter:title twitter:description].freeze
      def self.for(record, host:)
        new(record, host: host).run
      end

      def initialize(record, host:)
        @record = record
        @host = host.to_s.chomp("/")
        @findings = []
      end

      def run
        document = RenderedDocument.for(@record)
        if document.render_error.present?
          add(:error, "render_failed", "Page could not be rendered: #{document.render_error}")
        elsif document.available?
          analyze_document(document)
        else
          analyze_resolved_meta
        end

        {
          status: aggregate_status,
          label: HtmlValidationReport.label_for(aggregate_status),
          findings: @findings
        }
      end

      private

      def analyze_document(document)
        OG_REQUIRED.each do |property|
          value = document.meta_property(property)
          add(:error, "missing_#{property.tr(':', '_')}", "Missing #{property} meta tag") if value.blank?
        end

        TWITTER_REQUIRED.each do |name|
          value = document.meta_name(name)
          add(:error, "missing_#{name.tr(':', '_')}", "Missing #{name} meta tag") if value.blank?
        end

        [
          ["og:image", :property],
          ["twitter:image", :name]
        ].each do |key, kind|
          value = kind == :property ? document.meta_property(key) : document.meta_name(key)
          add(:warning, "missing_#{key.tr(':', '_')}", "Missing #{key} (recommended for link previews)") if value.blank?
        end
      end

      def analyze_resolved_meta
        return add(:error, "not_metatagable", "Record has no social meta configuration") unless @record.respond_to?(:meta_tag)

        resolved = Kubik::Metatagable::SocialMetaResolver.resolve(@record, host: @host)

        add(:error, "missing_og_title", "Missing Open Graph title") if resolved[:og_title].blank?
        add(:error, "missing_og_description", "Missing Open Graph description") if resolved[:og_description].blank?
        add(:error, "missing_twitter_card", "Missing Twitter card type") if resolved[:twitter_card_type].blank?

        add(:warning, "missing_og_image", "Missing Open Graph image") if resolved[:og_image].blank?
        add(:warning, "missing_twitter_image", "Missing Twitter image") if resolved[:twitter_image].blank?
      end

      def aggregate_status
        AggregateStatus.from_findings(@findings)
      end

      def add(severity, code, message)
        @findings << { severity: severity, code: code, message: message }
      end
    end
  end
end
