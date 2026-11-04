# frozen_string_literal: true

module KubikMetatagable
  class RunAllContentChecksJob < ApplicationJob
    queue_as :default

    def perform
      host = KubikMetatagable.configuration.content_checks_default_host
      host = host.call if host.respond_to?(:call)

      KubikMetatagable.content_checks_class_names.each do |class_name|
        klass = class_name.constantize
        next unless klass.kubik_content_checks_enabled?

        klass.find_each do |record|
          ContentChecksJob.perform_later(klass.name, record.id, host)
        end
      end
    end
  end
end
