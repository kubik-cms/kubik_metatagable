# frozen_string_literal: true

module Kubik
  module Discoverability
    module ActiveAdminExtension
      module_function

      def register!
        return unless defined?(KubikSettings)

        KubikSettings.configure do |config|
          config.add_active_admin_block do
            sidebar "Crawlers & robots", only: %i[edit show] do
              render partial: "kubik/discoverability/admin/settings_tab", locals: { resource: resource }
            end

            member_action :sync_crawler_catalog, method: :post do
              diff = Kubik::Discoverability::CatalogSync.diff_against_bundled
              resource.settings_hash = (resource.settings_hash || {}).merge("crawler_catalog_sync" => diff)
              resource.save!
              redirect_to admin_kubik_setting_path(resource),
                          notice: "Catalog check complete (#{diff[:new_count]} new vs bundled)."
            end

            member_action :regenerate_robots_txt, method: :post do
              Kubik::Discoverability.regenerate_robots_txt!(resource)
              redirect_to admin_kubik_setting_path(resource), notice: "robots.txt regenerated."
            end

            controller do
              before_action :merge_discoverability_settings_params, only: :update

              def merge_discoverability_settings_params
                raw = params.dig(:setting, :discoverability_settings)
                return if raw.blank?

                parsed = JSON.parse(raw)
                resource.settings_hash = (resource.settings_hash || {}).merge(parsed)
              rescue JSON::ParserError
                nil
              end
            end
          end
        end
      end
    end
  end
end
