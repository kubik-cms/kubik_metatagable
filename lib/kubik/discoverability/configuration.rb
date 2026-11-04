# frozen_string_literal: true

module Kubik
  module Discoverability
    class Configuration
      # category key => { discover: :allow|:block|:inherit, learn: ... }
      attr_accessor :category_defaults

      def initialize
        @category_defaults = {
          "ai-search" => { discover: :allow, learn: :inherit },
          "search" => { discover: :allow, learn: :inherit },
          "ai-training" => { discover: :inherit, learn: :block },
          "dataset" => { discover: :inherit, learn: :block },
          "user-fetch" => { discover: :allow, learn: :allow },
          "preview" => { discover: :allow, learn: :allow },
          "seo" => { discover: :allow, learn: :inherit },
          "tool" => { discover: :allow, learn: :inherit },
          "archive" => { discover: :allow, learn: :block }
        }
      end

      def default_for(category, axis)
        row = category_defaults[category.to_s] || {}
        row[axis] || :inherit
      end
    end
  end
end
