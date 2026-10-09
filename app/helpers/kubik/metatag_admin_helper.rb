# frozen_string_literal: true

module Kubik
  # Active Admin helpers shared by every metataggable resource.
  module MetatagAdminHelper
    FIELDSET_HEADER_PARTIAL = "active_admin/kubik/fieldset_header"
    LEGACY_FIELDSET_HEADER_PARTIAL = "admin/shared/fieldset_header"

    def self.resolve_fieldset_header_partial(lookup_context = nil)
      if lookup_context&.template_exists?(FIELDSET_HEADER_PARTIAL, [], true)
        FIELDSET_HEADER_PARTIAL
      elsif lookup_context&.template_exists?(LEGACY_FIELDSET_HEADER_PARTIAL, [], true)
        LEGACY_FIELDSET_HEADER_PARTIAL
      else
        FIELDSET_HEADER_PARTIAL
      end
    end

    def kubik_metatagable_fieldset_header_partial
      Kubik::MetatagAdminHelper.resolve_fieldset_header_partial(lookup_context)
    end

    # Host apps (e.g. kubik_ai) may define kubik_ai_metatag_form_actions(metatagable, focus).
    def kubik_metatagable_form_header_actions(metatagable, focus = nil)
      return unless respond_to?(:kubik_ai_metatag_form_actions, true)

      kubik_ai_metatag_form_actions(metatagable, focus)
    end

    def kubik_metatag_social_upload_thumbnail_url(upload)
      return unless upload.present?

      if upload.respond_to?(:admin_file_thumbnail)
        upload.admin_file_thumbnail
      elsif upload.respond_to?(:image_url)
        upload.image_url(:thumb_200x200)
      end
    end

    def render_kubik_metatag_social_share_previews(metatagable:, host:)
      meta = Kubik::Metatagable::SocialMetaResolver.resolve(metatagable, host: host)
      render partial: "kubik/metatagable/social_share_previews", locals: { meta: meta, admin_compact: true }
    end

    def render_kubik_metatag_admin_show_seo(metatagable:)
      render partial: "admin/show/meta_tag_seo_helper", locals: { resource: metatagable }
    end

    def render_kubik_metatag_admin_show_social(metatagable:)
      render partial: "admin/show/meta_tag_social_helper", locals: { resource: metatagable }
    end

    def render_kubik_metatag_admin_show_meta_tab(metatagable:)
      safe_join([
        render_kubik_metatag_admin_show_seo(metatagable: metatagable),
        render_kubik_metatag_admin_show_social(metatagable: metatagable)
      ])
    end

    def render_kubik_metatag_admin_form_seo(f:)
      render partial: "admin/form/meta_tag_seo_helper", locals: { f: f }
    end

    def render_kubik_metatag_admin_form_social(f:)
      render partial: "admin/form/meta_tag_social_helper", locals: { f: f }
    end

    def render_kubik_metatag_admin_form_meta_tab(f:)
      safe_join([
        render_kubik_metatag_admin_form_seo(f: f),
        render_kubik_metatag_admin_form_social(f: f)
      ])
    end
  end
end
