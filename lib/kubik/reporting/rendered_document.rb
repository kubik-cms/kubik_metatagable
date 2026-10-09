# frozen_string_literal: true

module Kubik
  module Reporting
    class RenderedDocument
      attr_reader :render_error

      def self.for(record)
        html, error = fetch_html(record)
        return new(nil, render_error: error) if html.blank?

        new(html)
      end

      def self.fetch_html(record)
        renderer = html_renderer
        return [nil, nil] unless renderer

        [renderer.call(record), nil]
      rescue StandardError => e
        [nil, e.message]
      end

      def self.html_renderer
        return unless defined?(KubikPublishable)

        KubikPublishable.config.html_quality_renderer
      end

      def initialize(html, render_error: nil)
        @html = html
        @render_error = render_error
        @doc = html.present? ? Nokogiri::HTML(html) : nil
      end

      def available?
        @doc.present?
      end

      def nokogiri_document
        @doc
      end

      def title
        @doc.at("title")&.text&.strip
      end

      def meta_name(name)
        @doc.at("meta[name='#{name}']")&.[]("content")&.strip
      end

      def meta_property(property)
        @doc.at("meta[property='#{property}']")&.[]("content")&.strip
      end

      def link_rel(rel)
        @doc.at("link[rel='#{rel}']")&.[]("href")&.strip
      end
    end
  end
end
