# frozen_string_literal: true

namespace :kubik do
  namespace :metatagable do
    desc "Refresh persisted content checks for all configured CMS models"
    task refresh_content_checks: :environment do
      host = KubikMetatagable.configuration.content_checks_default_host
      host = host.call if host.respond_to?(:call)

      KubikMetatagable.content_checks_class_names.each do |class_name|
        klass = class_name.constantize
        next unless klass.kubik_content_checks_enabled?

        puts "Refreshing #{class_name}…"
        klass.find_each do |record|
          Kubik::Reporting::Runner.run!(record, host: host)
        end
      end
    end
  end
end
