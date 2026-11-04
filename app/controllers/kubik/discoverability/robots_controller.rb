# frozen_string_literal: true

module Kubik
  module Discoverability
    class RobotsController < ActionController::Base
      def show
        body = Rails.cache.fetch("kubik/robots_txt", expires_in: 1.hour) do
          Kubik::Discoverability.robots_txt_body
        end
        render plain: body, content_type: "text/plain"
      end
    end
  end
end
