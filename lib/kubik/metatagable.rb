# frozen_string_literal: true

module Kubik
  module Metatagable
    extend ActiveSupport::Concern

    TITLE_FIELDS = %i[title_tag og_title twitter_title].freeze
    DESCRIPTION_FIELDS = %i[
      meta_description og_description twitter_description
    ].freeze
    MEDIA_FIELDS = %i[
      og_image twitter_media
    ].freeze

    class_methods do
      def kubik_metatagable_settings
        @kubik_metatagable_settings || {}
      end

      private

      def kubik_metatagable(opts = {})
        options = {
          defaults: false, title: nil, description: nil, image: nil
        }.merge(opts)
        @kubik_metatagable_settings = options
      end
    end

    included do
      has_one :meta_tag,
              class_name: "Kubik::MetaTag",
              as: :metatagable,
              dependent: :destroy

      include Kubik::ContentChecksCheckable

      before_save :apply_defaults

      accepts_nested_attributes_for :meta_tag, allow_destroy: true

      def meta_tag
        super || build_meta_tag
      end
    end

    def apply_defaults
      return unless kubik_metatagable_default

      build_meta_tag if meta_tag.nil?

      update_meta_titles if kubik_metatagable_title.present?
      update_meta_descriptions if kubik_metatagable_description.present?
      update_meta_medias if kubik_metatagable_media.present?
    end

    def update_meta_title(field)
      return unless meta_tag.send(field).blank?

      meta_tag.update_attribute(field, kubik_metatagable_title)
    end

    def update_meta_description(field)
      return unless meta_tag.send(field).blank?

      meta_tag.update_attribute(field, kubik_metatagable_description)
    end

    def update_meta_media(field)
      return unless meta_tag.send(field).blank?

      meta_tag.update_attribute(field, kubik_metatagable_media)
    end

    def kubik_metatagable_default
      default_setting = self.class.kubik_metatagable_settings[:defaults]
      default_setting.is_a?(Proc) ? default_setting.call(self) : default_setting
    end

    def kubik_metatagable_title
      title_setting = self.class.kubik_metatagable_settings[:title]
      title_setting.is_a?(Proc) ? title_setting.call(self) : title_setting
    end

    def kubik_metatagable_description
      description_setting = self.class.kubik_metatagable_settings[:description]
      description_setting.is_a?(Proc) ? description_setting.call(self) : description_setting
    end

    def kubik_metatagable_media
      media_setting = self.class.kubik_metatagable_settings[:image]
      media_setting.is_a?(Proc) ? media_setting.call(self) : media_setting
    end

    def update_meta_titles
      TITLE_FIELDS.each do |field|
        update_meta_title(field)
      end
    end

    def update_meta_descriptions
      DESCRIPTION_FIELDS.each do |field|
        update_meta_description(field)
      end
    end

    def update_meta_medias
      MEDIA_FIELDS.each do |field|
        update_meta_media(field)
      end
    end
  end
end
