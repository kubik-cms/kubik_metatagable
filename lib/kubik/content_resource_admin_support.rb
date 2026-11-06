# frozen_string_literal: true

module Kubik
  module ContentResourceAdminSupport
    def self.included(dsl)
      klass = dsl.config.resource_class_name.constantize

      dsl.include Kubik::PublishableAdminAction if Kubik::ContentResourceAdmin.model_publishable?(klass)
      dsl.include Kubik::PreviewCapturesAdminAction if Kubik::ContentResourceAdmin.model_preview_captures?(klass)
      dsl.include Kubik::PreviewableAdminAction if Kubik::ContentResourceAdmin.model_previewable?(klass)
      dsl.include Kubik::HtmlQualityAdminAction if Kubik::ContentResourceAdmin.model_html_quality?(klass)

      if Kubik::ContentResourceAdmin.content_versions_enabled? && Kubik::ContentResourceAdmin.model_versionable?(klass)
        dsl.include Kubik::ContentVersionAdminSupport
        dsl.include Kubik::VersionableAdminAction
      end

      if defined?(KubikAi::ActiveAdmin::MetatagActions) &&
         Kubik::ContentResourceAdmin.model_metatagable?(klass)
        dsl.include KubikAi::ActiveAdmin::MetatagActions
      end

      return unless Kubik::ContentResourceAdmin.model_previewable?(klass)

      preview_action = preview_member_action_name(klass)

      dsl.controller do
        include Kubik::AdminPreviewRecord if defined?(Kubik::AdminPreviewRecord)

        define_method preview_action do
          record = respond_to?(:kubik_admin_preview_record) ? kubik_admin_preview_record : resource

          renderer = Kubik::ContentResourceAdmin.preview_html_renderer
          if renderer
            html = renderer.call(self, record)
            if html
              render html: html.html_safe, layout: false
              return
            end
          end

          record.kubik_previewable_instance_variables.each do |name, value|
            instance_variable_set("@#{name}", value)
          end
          layout = record.kubik_previewable_layout
          layout = "application" if layout == false
          render layout: layout,
                 template: record.kubik_previewable_template,
                 locals: record.kubik_previewable_locals
        end
      end
    end

    def self.preview_member_action_name(klass)
      :"preview_#{klass.model_name.singular_route_key}"
    end
  end
end
