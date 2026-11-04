# frozen_string_literal: true

module Kubik
  module Discoverability
    module EngineExtensions
      extend ActiveSupport::Concern

      included do
        initializer "kubik_metatagable.discoverability_routes" do |app|
          app.routes.prepend do
            get "/robots.txt", to: "kubik/discoverability/robots#show", format: false
            get "/llms.txt", to: "kubik/discoverability/llms#show", format: false
          end
        end

        initializer "kubik_metatagable.discoverability_settings_cache" do
          ActiveSupport.on_load(:active_record) do
            if defined?(Kubik::Setting)
              Kubik::Setting.class_eval do
                unless method_defined?(:flush_discoverability_caches)
                  after_commit :flush_discoverability_caches, on: %i[create update]

                  def flush_discoverability_caches
                    Kubik::Discoverability.flush_caches!
                  end
                end
              end
            end
          end
        end

        initializer "kubik_metatagable.discoverability_seo_helper" do
          ActiveSupport.on_load(:action_view) do
            include Kubik::SeoHelper
          end
        end

        initializer "kubik_metatagable.discoverability_admin" do
          ActiveSupport.on_load(:active_admin) do
            require "kubik/discoverability/active_admin_extension"
            Kubik::Discoverability::ActiveAdminExtension.register!
          end
        end
      end
    end
  end
end
