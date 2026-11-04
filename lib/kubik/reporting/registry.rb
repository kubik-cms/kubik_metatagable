# frozen_string_literal: true

module Kubik
  module Reporting
    # Extensible registry of content checks (SEO, HTML validity, GEO, etc.).
    # Sister gems register checks with `register`; admin UI reads `ui_items`.
    module Registry
      Check = Struct.new(:key, :label, :ui, :available, :run, keyword_init: true)

      @checks = []

      class << self
        def register(key, label:, ui: {}, available: ->(_record) { true }, &run)
          @checks.reject! { |check| check.key == key.to_sym }
          @checks << Check.new(
            key: key.to_sym,
            label: label,
            ui: ui,
            available: available,
            run: run
          )
        end

        def checks
          @checks
        end

        def checks_for(record)
          checks.select { |check| check.available.call(record) }
        end

        def ui_items(record = nil)
          scope = record ? checks_for(record) : checks
          scope.map do |check|
            {
              key: check.key,
              label: check.label,
              **check.ui
            }
          end
        end

        def run_live_check(key, record, host:)
          check = checks.find { |entry| entry.key == key.to_sym }
          raise ArgumentError, "unknown check #{key}" unless check
          raise ArgumentError, "check #{key} not available" unless check.available.call(record)

          normalize_result(check.run.call(record, host: host))
        end

        def normalize_result(result)
          result = result.deep_stringify_keys if result.respond_to?(:deep_stringify_keys)
          result.deep_symbolize_keys
        end
      end
    end
  end
end
