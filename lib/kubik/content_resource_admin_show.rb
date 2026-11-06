# frozen_string_literal: true

module Kubik
  module ContentResourceAdminShow
    @details_partials = {}

    module DSL
      def kubik_content_resource_show(details_partial:)
        Kubik::ContentResourceAdminShow.register_details_partial(config.resource_class, details_partial)
      end
    end

    class << self
      def register_details_partial(klass, partial)
        @details_partials[klass.name] = partial
      end

      def details_partial_for(klass)
        @details_partials[klass.name]
      end

      def included(dsl)
        dsl.extend(DSL)

        dsl.send(:show) do |record|
          details_partial = Kubik::ContentResourceAdminShow.details_partial_for(record.class)
          details_title = "#{record.model_name.human} details"

          tabs do
            tab "Content" do
              div class: "kubik-admin-show-panels" do
                panel "Details", class: "panel__double" do
                  div class: "kubik-admin-fieldset" do
                    render partial: "active_admin/kubik/fieldset_header", locals: { title: details_title }

                    div class: "kubik-admin-fieldset__body" do
                      if details_partial.present?
                        render partial: details_partial, locals: { record: record }
                      else
                        attributes_table_for record do
                          row :id
                          row :title if record.respond_to?(:title)
                        end
                      end
                    end
                  end

                  render partial: "admin/kubik/content_resource_details_status", locals: { record: record }
                end

                if helpers.kubik_content_resource_preview_panel?(record)
                  panel "Preview", class: "panel__double" do
                    render partial: "kubik_previewable/admin/preview_captures_panel", locals: { record: record }
                  end
                end
              end
            end

            if Kubik::ContentResourceAdmin.model_metatagable?(record.class) &&
               !helpers.kubik_content_resource_admin_insights_suppressed?(record)
              tab "SEO" do
                render "admin/metatagable/show_seo_tab", metatagable: record
              end
              tab "GEO" do
                render "admin/metatagable/show_geo_tab", metatagable: record
              end
              tab "Social Media" do
                render "admin/metatagable/show_social_tab", metatagable: record
              end
            end
          end
        end

        dsl.action_item(:kubik_content_preview, only: :show, if: proc {
          Kubik::ContentResourceAdmin.model_previewable?(resource.class) &&
            !helpers.kubik_content_resource_managed_zone_page?(resource) &&
            helpers.kubik_admin_preview_path(resource).present?
        }) do
          link_to "Preview",
                  helpers.kubik_admin_preview_path(resource),
                  target: "_blank",
                  rel: "noopener"
        end
      end
    end
  end
end
