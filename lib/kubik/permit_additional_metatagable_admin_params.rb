# frozen_string_literal: true

module Kubik
  # PermitAdditionalAdminParams module
  module PermitAdditionalMetatagableAdminParams
    extend self

    def push_to_params(klass, params)
      return unless klass.send(:reflect_on_association, :meta_tag)
      params.push meta_tag_attributes(klass)
    end

    private

    def meta_tag_attributes(klass)
      {
        meta_tag_attributes: [
          :id, :title_tag, :meta_description, :og_type, :og_title, :og_description, :og_image,
          :twitter_title, :twitter_description, :twitter_media, :twitter_card_type,
          og_image_upload_attributes: [:kubik_media_upload_id, :id, :_destroy],
          twitter_image_upload_attributes: [:kubik_media_upload_id, :id, :_destroy]
        ]
      }
    end
  end
end
