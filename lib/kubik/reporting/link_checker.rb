# frozen_string_literal: true

require "net/http"
require "uri"

module Kubik
  module Reporting
    class LinkChecker
      SKIP_SCHEMES = %w[mailto tel javascript data].freeze
      MAX_LINKS = 15

      def self.enabled?
        ENV.fetch("KUBIK_SEO_LINK_CHECKING", "1") != "0"
      end

      def self.check(hrefs, host:)
        return [] unless enabled?

        new(host: host).check(hrefs)
      end

      def initialize(host:)
        @base = URI.parse(host.to_s.chomp("/"))
      end

      def check(hrefs)
        broken = []
        hrefs.take(MAX_LINKS).each do |href|
          result = check_href(href)
          broken << result if result
        end
        broken
      end

      def check_href(href)
        return { href: href, reason: "Empty link" } if href.blank?

        uri = resolve(href)
        return nil if uri.nil?
        return nil if skip_uri?(uri)

        return { href: href, reason: "Could not resolve URL" } unless reachable?(uri)

        nil
      end

      private

      def resolve(href)
        URI.join(@base, href)
      rescue URI::Error
        nil
      end

      def skip_uri?(uri)
        return true if uri.fragment && uri.path.blank? && uri.host.nil?

        scheme = uri.scheme&.downcase
        SKIP_SCHEMES.include?(scheme)
      end

      def reachable?(uri)
        return false if uri.host.blank?

        cache_fetch(uri) { head_request(uri) }
      end

      def cache_fetch(uri, &block)
        return yield unless defined?(Rails) && Rails.respond_to?(:cache) && Rails.cache

        Rails.cache.fetch("kubik/reporting/link_check/#{uri}", expires_in: 10.minutes, &block)
      end

      def head_request(uri)
        Net::HTTP.start(
          uri.host,
          uri.port,
          use_ssl: uri.scheme == "https",
          open_timeout: 1,
          read_timeout: 1
        ) do |http|
          response = http.request(Net::HTTP::Head.new(uri.request_uri))
          return true if response.code.to_i < 400
          return true if response.code.to_i == 405 && get_ok?(http, uri)

          false
        end
      rescue StandardError
        false
      end

      def get_ok?(http, uri)
        response = http.request(Net::HTTP::Get.new(uri.request_uri))
        response.code.to_i < 400
      rescue StandardError
        false
      end
    end
  end
end
