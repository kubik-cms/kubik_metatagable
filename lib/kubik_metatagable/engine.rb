# frozen_string_literal: true

module KubikMetatagable
  class Engine < ::Rails::Engine
    include Kubik::Discoverability::EngineExtensions

    isolate_namespace KubikMetatagable

    config.autoload_paths += Dir["#{root}/app/jobs"]

    # Loaded explicitly so ActionView can include it during lazy hooks.
    require File.expand_path("../../app/helpers/kubik/metatag_admin_helper", __dir__)
    require File.expand_path("../../app/helpers/kubik/reporting_admin_helper", __dir__)
    require File.expand_path("../../app/helpers/kubik/content_resource_admin_helper", __dir__)

    initializer "kubik_metatagable.assets" do |app|
      %w[javascripts stylesheets].each do |asset_dir|
        path = root.join("app", "assets", asset_dir)
        app.config.assets.paths << path.to_s if path.directory?
      end

      app.config.assets.precompile += %w[
        kubik_metatagable/share_controller.js
      ]
    end

    initializer "kubik_metatagable.i18n" do |app|
      app.config.i18n.load_path += Dir[root.join("config", "locales", "**", "*.{rb,yml}")]
    end

    initializer "kubik_metatagable.action_view" do
      ActiveSupport.on_load(:action_view) do
        include Kubik::MetatagAdminHelper
        include Kubik::ReportingAdminHelper
        include Kubik::ContentResourceAdminHelper
      end
    end

    initializer "kubik_metatagable.active_admin_helpers" do
      config.to_prepare do
        next unless defined?(ActiveAdmin::BaseController)

        ActiveAdmin::BaseController.helper Kubik::ContentResourceAdminHelper
        ActiveAdmin::BaseController.helper Kubik::ReportingAdminHelper
      end
    end
  end
end
