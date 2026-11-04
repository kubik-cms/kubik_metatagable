# frozen_string_literal: true

module Kubik
  class ContentChecksReport < ApplicationRecord
    self.table_name = "kubik_content_checks_reports"

    belongs_to :checkable, polymorphic: true

    validates :checkable, presence: true

    def self.table_available?
      table_exists?
    rescue StandardError
      false
    end
  end
end
