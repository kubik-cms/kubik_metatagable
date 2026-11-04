# frozen_string_literal: true

class CreateKubikContentChecksReports < ActiveRecord::Migration[6.0]
  def change
    create_table :kubik_content_checks_reports do |t|
      t.references :checkable, polymorphic: true, null: false, index: { unique: true }
      t.jsonb :report, null: false, default: {}
      t.timestamps
    end
  end
end
