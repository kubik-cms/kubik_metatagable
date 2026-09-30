# frozen_string_literal: true

module Kubik
  module Metatagable
    module MetaTagSeo
      extend ActiveSupport::Concern

      def robots_meta_content
        directives = []
        directives << "noindex" if robots_noindex?
        directives << "nofollow" if robots_nofollow?
        directives << "noarchive" if robots_noarchive?
        directives << "nosnippet" if robots_nosnippet?
        if block_ai_crawlers?
          directives << "noai"
          directives << "noimageai"
        end
        directives.join(", ").presence
      end
    end
  end
end
