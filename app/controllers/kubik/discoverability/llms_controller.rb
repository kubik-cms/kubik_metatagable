# frozen_string_literal: true

module Kubik
  module Discoverability
    class LlmsController < ActionController::Base
      def show
        body = Rails.cache.fetch("kubik/llms_txt", expires_in: 1.hour) do
          Kubik::Discoverability.llms_txt_body
        end
        render plain: body, content_type: "text/plain; charset=utf-8"
      end
    end
  end
end
