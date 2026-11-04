# frozen_string_literal: true

module Kubik
  module Discoverability
    class Error < StandardError; end

    STANCES = %i[inherit allow block].freeze

    class << self
      def configuration
        @configuration ||= Configuration.new
      end

      def configure
        yield(configuration)
      end

      def robots_txt_body
        settings = SettingsStore.current
        body = settings["robots_txt_body"].presence
        return body if body.present?

        RobotsTxtBuilder.generate(settings)
      end

      def llms_txt_body
        settings = SettingsStore.current
        LlmsTxtBuilder.render(settings)
      end

      def flush_caches!
        Rails.cache.delete("kubik/robots_txt")
        Rails.cache.delete("kubik/llms_txt")
      end

      def regenerate_robots_txt!(settings_record = nil)
        settings = SettingsStore.normalize(settings_record)
        generated = RobotsTxtBuilder.generate(settings)
        settings_hash = settings_record.is_a?(Hash) ? settings_record : settings_record&.settings_hash
        return generated unless settings_hash

        settings_hash["robots_txt_generated"] = generated
        unless settings["robots_txt_lock_custom"]
          settings_hash["robots_txt_body"] = generated
        end
        settings_record.save! if settings_record.respond_to?(:save!)
        flush_caches!
        generated
      end
    end
  end
end

require "kubik/discoverability/configuration"
require "kubik/discoverability/settings_store"
require "kubik/discoverability/bot_catalog"
require "kubik/discoverability/policy_resolver"
require "kubik/discoverability/robots_txt_builder"
require "kubik/discoverability/llms_txt_builder"
require "kubik/discoverability/catalog_sync"
