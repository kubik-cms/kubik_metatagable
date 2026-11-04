# frozen_string_literal: true

module Kubik
  module ContentChecksCheckable
    extend ActiveSupport::Concern

    included do
      has_one :kubik_content_checks_report,
              class_name: "Kubik::ContentChecksReport",
              as: :checkable,
              dependent: :destroy,
              inverse_of: :checkable

      after_commit :enqueue_kubik_content_checks, on: %i[create update], unless: :skip_kubik_content_checks_enqueue?
    end

    class_methods do
      def kubik_content_checks_enabled?
        return false unless defined?(Kubik::ContentChecksReport) && Kubik::ContentChecksReport.table_available?
        return false unless included_modules.include?(Kubik::ContentChecksCheckable)

        class_names = KubikMetatagable.content_checks_class_names
        class_names.include?(name)
      end
    end

    private

    def skip_kubik_content_checks_enqueue?
      return true if Rails.env.test? && !KubikMetatagable.configuration.content_checks_enqueue_in_test
      return true unless self.class.kubik_content_checks_enabled?

      false
    end

    def enqueue_kubik_content_checks
      KubikMetatagable::ContentChecksJob.perform_later(self.class.name, id)
    end
  end
end
