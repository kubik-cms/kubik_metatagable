# frozen_string_literal: true

module KubikMetatagable
  class ContentChecksJob < ApplicationJob
    queue_as :default

    def perform(class_name, record_id, host = nil)
      record = class_name.constantize.find_by(id: record_id)
      return unless record
      return unless record.class.kubik_content_checks_enabled?

      Kubik::Reporting::Runner.run!(record, host: host)
    end
  end
end
