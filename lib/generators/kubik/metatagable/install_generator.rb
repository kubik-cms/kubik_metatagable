# frozen_string_literal: true

require "rails/generators/active_record"

module Kubik
  module Generators
    module Metatagable
      class InstallGenerator < ActiveRecord::Generators::Base
        source_root File.expand_path("templates", __dir__)
        desc "Running Kubik Metatggable generators"
        argument :name, type: :string, default: "kubik"

        def db_migrations
          migration_template("migrations/create_kubik_meta_tags.rb.erb",
                             "db/migrate/create_kubik_meta_tags.rb",
                             migration_version: migration_version)
        end

        def install_notice
          say "After updating kubik_metatagable, run: bin/rails kubik:metatagable:upgrade", :green
          say "Then: bin/rails db:migrate", :green
        end

        private

        def migration_version
          "[#{Rails::VERSION::MAJOR}.#{Rails::VERSION::MINOR}]"
        end
      end
    end
  end
end
