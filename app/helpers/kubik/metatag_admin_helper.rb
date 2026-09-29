# frozen_string_literal: true

module Kubik
  # Active Admin helpers shared by every metataggable resource.
  module MetatagAdminHelper
    FIELDSET_HEADER_PARTIAL = "active_admin/kubik/fieldset_header"
    LEGACY_FIELDSET_HEADER_PARTIAL = "admin/shared/fieldset_header"

    def kubik_metatagable_fieldset_header_partial
      if lookup_context.template_exists?(FIELDSET_HEADER_PARTIAL, [], true)
        FIELDSET_HEADER_PARTIAL
      else
        LEGACY_FIELDSET_HEADER_PARTIAL
      end
    end

    # Host apps (e.g. kubik_ai) may define kubik_ai_metatag_form_actions(metatagable, focus).
    def kubik_metatagable_form_header_actions(metatagable, focus = nil)
      return unless respond_to?(:kubik_ai_metatag_form_actions, true)

      kubik_ai_metatag_form_actions(metatagable, focus)
    end

    def render_kubik_metatag_social_share_previews(metatagable:, host:)
      meta = Kubik::Metatagable::SocialMetaResolver.resolve(metatagable, host: host)
      render partial: "kubik/metatagable/social_share_previews", locals: { meta: meta }
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
