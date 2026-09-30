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
end

require "kubik_metatagable/version"
require "kubik_metatagable/social_meta_images"
require "kubik_metatagable/engine"

module Kubik
  require "kubik/metatagable"
  require "kubik/metatagable/controller_methods"
  require "kubik/metatagable/configuration"
  require "kubik/metatagable/social_meta_resolver"
  require "kubik/metatagable/meta_tag_seo"
  require "kubik/permit_additional_metatagable_admin_params"
end
