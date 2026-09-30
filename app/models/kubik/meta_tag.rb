# frozen_string_literal: true

module Kubik
  class MetaTag < ApplicationRecord
    include Kubik::Metatagable::MetaTagSeo

    self.table_name = "kubik_meta_tags"

    belongs_to :metatagable, polymorphic: true

    TWITTER_CARD_TYPES = %i[summary summary_large_image player].freeze

    if defined?(Kubik::Uploadable)
      include Kubik::Uploadable
      has_one_kubik_upload(self, :og_image_upload)
      has_one_kubik_upload(self, :twitter_image_upload)
    end

    def self.ransackable_attributes(auth_object = nil)
      ["created_at", "id", "meta_description", "metatagable_id", "metatagable_type", "og_description", "og_image", "og_title", "title_tag", "twitter_card_type", "twitter_description", "twitter_media", "twitter_title", "updated_at"]
    end


    def self.ransackable_associations(auth_object = nil)
      ["kubik_media_upload", "uploadable"]
    end
  end
end
