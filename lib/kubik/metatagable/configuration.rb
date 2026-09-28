# frozen_string_literal: true

module Kubik
  module Metatagable
    class Configuration
      attr_accessor :settings_class
      attr_accessor :share_button_meta_classes
      attr_accessor :share_button_footer_classes
      attr_accessor :social_image_derivative
      attr_accessor :default_og_type_resolver

      def initialize
        @canonical_path_resolvers = {}
        @social_image_derivative = KubikMetatagable::SocialMetaImages::DEFAULT_DERIVATIVE
      end

      def register_canonical_path(model_name, &block)
        @canonical_path_resolvers[model_name.to_s] = block
      end

      def canonical_path_for(record, routes)
        resolver = @canonical_path_resolvers[record.class.name]
        return "/" unless resolver

        resolver.call(record, routes)
      end

      def default_og_type_for(record)
        if default_og_type_resolver.respond_to?(:call)
          default_og_type_resolver.call(record)
        else
          "website"
        end
      end

      def settings_class
        @settings_class&.constantize || (defined?(Kubik::Setting) ? Kubik::Setting : nil)
      end

      def share_button_meta_classes
        @share_button_meta_classes.to_s
      end

      def share_button_footer_classes
        @share_button_footer_classes.to_s
      end
    end
  end
end
