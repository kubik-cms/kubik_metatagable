# frozen_string_literal: true

module Kubik
  module Discoverability
    module SettingsStore
      module_function

      def current
        record = settings_record
        normalize(record)
      end

      def normalize(record)
        hash = if record.is_a?(Hash)
                 record
               elsif record.respond_to?(:settings_hash)
                 record.settings_hash || {}
               else
                 {}
               end
        hash.with_indifferent_access
      end

      def settings_record
        if defined?(Kubik::Setting)
          Kubik::Setting.instance
        else
          {}
        end
      rescue StandardError
        {}
      end
    end
  end
end
