# frozen_string_literal: true

require "rails/generators/active_record"

module Kubik
  module Generators
    module Metatagable
      class UpgradeGenerator < ActiveRecord::Generators::Base
        source_root File.expand_path("templates", __dir__)
        desc "Copy pending Kubik Metatagable migrations into the host application"
        argument :name, type: :string, default: "kubik_metatagable"

        def add_seo_settings_migration
          if seo_settings_columns_present?
            say "kubik_meta_tags SEO settings columns already present — no migration added.", :green
            return
          end

          migration_template(
            "migrations/add_seo_settings_to_kubik_meta_tags.rb.erb",
            "db/migrate/add_seo_settings_to_kubik_meta_tags.rb",
            migration_version: migration_version
          )
        end

        def upgrade_notice
          say "Run bin/rails db:migrate when migrations were added.", :green
        end

        private

        def migration_version
          "[#{Rails::VERSION::MAJOR}.#{Rails::VERSION::MINOR}]"
        end

        def seo_settings_columns_present?
          return false unless ActiveRecord::Base.connection.table_exists?(:kubik_meta_tags)

          ActiveRecord::Base.connection.column_exists?(:kubik_meta_tags, :share_enabled)
        rescue StandardError
          false
        end
      end
    end
  end
end
