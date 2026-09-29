# frozen_string_literal: true

namespace :kubik do
  namespace :metatagable do
    desc "Install Kubik Metatagable migrations"
    task install: :environment do
      require "rails/generators"
      Rails::Generators.invoke("kubik:metatagable:install")
    end

    desc "Add pending Kubik Metatagable migrations"
    task upgrade: :environment do
      require "rails/generators"
      Rails::Generators.invoke("kubik:metatagable:upgrade")
    end
  end
end
