# frozen_string_literal: true

module KubikMetatagable
  class Engine < ::Rails::Engine
    isolate_namespace KubikMetatagable

    # Loaded explicitly so ActionView can include it during lazy hooks.
    require File.expand_path("../../app/helpers/kubik/metatag_admin_helper", __dir__)

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
      end
    end
  end
end
