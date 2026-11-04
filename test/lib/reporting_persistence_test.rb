# frozen_string_literal: true

require "test_helper"

class KubikReportingPersistenceTest < ActiveSupport::TestCase
  test "summary_for reads stored seo check from polymorphic report" do
    record = examples(:one)
    skip "kubik_content_checks_reports table missing" unless Kubik::ContentChecksReport.table_available?

    Kubik::ContentChecksReport.create!(
      checkable: record,
      report: {
        "checked_at" => Time.current.iso8601,
        "host" => "https://example.test",
        "checks" => {
          "seo" => {
            "status" => "red",
            "label" => "Issues",
            "findings" => [{ "severity" => "error", "code" => "missing_title", "message" => "Missing title" }],
            "linters" => []
          }
        }
      }
    )

    summary = Kubik::Reporting.summary_for(record, host: "https://example.test")
    assert_equal :red, summary[:seo][:status]
    assert_equal 1, summary[:seo][:findings].size
  end

  test "registry includes geo check when geo integration is loaded" do
    keys = Kubik::Reporting::Registry.checks.map(&:key)
    assert_includes keys, :seo
    assert_includes keys, :sharing
    assert_includes keys, :geo
  end
end
