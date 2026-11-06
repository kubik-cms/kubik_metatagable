# frozen_string_literal: true

require "activeadmin"

module KubikMetatagable
  class Error < StandardError; end
  class << self
    attr_accessor :configuration
  end

  def self.configuration
    @configuration ||= ::Kubik::Metatagable::Configuration.new
  end

  def self.configure
    yield(configuration)
  end

  def self.content_checks_class_names
    configured = configuration.content_checks_classes
    list = Array(configured).presence
    if list.blank? && defined?(KubikPublishable)
      list = KubikPublishable.config.html_quality_classes
    end
    Array(list).map(&:to_s)
  end
end

require "kubik_metatagable/version"
require "kubik_metatagable/social_meta_images"
require "kubik/discoverability"
require "kubik/discoverability/engine_extensions"
require "kubik_metatagable/engine"

module Kubik
  require "kubik/metatagable"
  require "kubik/metatagable/controller_methods"
  require "kubik/metatagable/configuration"
  require "kubik/metatagable/social_meta_resolver"
  require "kubik/metatagable/social_meta_backfill"
  require "kubik/metatagable/meta_tag_seo"
  require "kubik/permit_additional_metatagable_admin_params"
  require "kubik/reporting"
  require "kubik/metatagable/geo_reporting_integration"
  require "kubik/content_resource_admin"
  require "kubik/content_resource_admin_support"
  require "kubik/content_resource_admin_show"
  require "kubik/content_checks_checkable"
end
