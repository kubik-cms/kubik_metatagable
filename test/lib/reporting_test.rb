# frozen_string_literal: true

require "test_helper"

class KubikReportingTest < ActiveSupport::TestCase
  test "seo report flags missing description in rendered html" do
    html = "<html><head><title>Hello</title></head><body></body></html>"
    document = Kubik::Reporting::RenderedDocument.new(html)
    report = Kubik::Reporting::SeoReport.new(examples(:one), host: "https://example.test")
    linters = report.send(:linters_from_document, document)
    report.instance_variable_set(:@linters, linters)
    report.instance_variable_set(:@findings, report.send(:linters_to_findings, linters))

    assert_equal :red, report.send(:aggregate_status)
    description_linter = linters.find { |l| l[:key] == :meta_description }
    assert_equal :red, description_linter[:status]
    assert report.instance_variable_get(:@findings).any? { |f| f[:code] == "missing_meta_description" }
  end

  test "seo report lists all linters with green status when page is healthy" do
    html = <<~HTML
      <html><head>
        <title>Short title</title>
        <meta name="description" content="A meta description that is comfortably within the recommended length for search snippets.">
        <meta name="robots" content="index, follow">
        <link rel="canonical" href="https://example.test/page">
      </head><body><h1>Short title</h1><img src="/ok.png" alt="Illustration"></body></html>
    HTML
    document = Kubik::Reporting::RenderedDocument.new(html)
    report = Kubik::Reporting::SeoReport.new(examples(:one), host: "https://example.test")
    linters = report.send(:linters_from_document, document)

    assert_equal Kubik::Reporting::SeoReport::LINTERS.size, linters.size
    assert linters.all? { |l| l[:status] == :green }
  end

  test "sharing report flags missing og tags in rendered html" do
    html = <<~HTML
      <html><head>
        <meta property="og:title" content="T">
      </head><body></body></html>
    HTML
    document = Kubik::Reporting::RenderedDocument.new(html)
    report = Kubik::Reporting::SharingReport.new(examples(:one), host: "https://example.test")
    report.send(:analyze_document, document)

    assert_equal :red, report.send(:aggregate_status)
  end

  test "html validation status is green with no findings" do
    assert_equal :green, Kubik::Reporting::HtmlValidationReport.status_for_findings([])
  end

  test "html validation report is green when checked with no findings" do
    record = Struct.new(:last_html_quality_report).new(
      {
        "checked_at" => Time.current.iso8601,
        "findings" => [],
        "summary" => { "warnings" => 0 }
      }
    )
    result = Kubik::Reporting::HtmlValidationReport.for(record)
    assert_equal :green, result[:status]
    assert_equal "OK", result[:label]
  end

  test "html validation status is amber with warnings" do
    findings = [{ severity: "warning", code: "parse_error", message: "Unclosed tag" }]
    assert_equal :amber, Kubik::Reporting::HtmlValidationReport.status_for_findings(findings)
  end

  test "html validation status is amber not red for warnings-only render_failed severity" do
    findings = [{ severity: "warning", code: "render_failed", message: "timeout" }]
    assert_equal :amber, Kubik::Reporting::AggregateStatus.from_findings(findings)
  end

  test "html validation status is red for error severity" do
    findings = [{ severity: "error", code: "parse_error", message: "Fatal" }]
    assert_equal :red, Kubik::Reporting::HtmlValidationReport.status_for_findings(findings)
  end

  test "seo aggregate is amber when only warning-level linters fail" do
    html = <<~HTML
      <html><head>
        <title>Short title</title>
        <meta name="description" content="A meta description that is comfortably within the recommended length for search snippets.">
        <meta name="robots" content="index, follow">
        <link rel="canonical" href="https://example.test/page">
      </head><body><p>No heading</p></body></html>
    HTML
    document = Kubik::Reporting::RenderedDocument.new(html)
    report = Kubik::Reporting::SeoReport.new(examples(:one), host: "https://example.test")
    linters = report.send(:linters_from_document, document)
    report.instance_variable_set(:@linters, linters)
    report.instance_variable_set(:@findings, report.send(:linters_to_findings, linters))

    assert_equal :amber, report.send(:aggregate_status)
    assert report.instance_variable_get(:@findings).all? { |f| f[:severity] == :warning }
  end

  test "seo report flags missing h1 in rendered html" do
    html = <<~HTML
      <html><head>
        <title>Short title</title>
        <meta name="description" content="A meta description that is comfortably within the recommended length for search snippets.">
        <meta name="robots" content="index, follow">
        <link rel="canonical" href="https://example.test/page">
      </head><body><p>No heading</p></body></html>
    HTML
    document = Kubik::Reporting::RenderedDocument.new(html)
    report = Kubik::Reporting::SeoReport.new(examples(:one), host: "https://example.test")
    linters = report.send(:linters_from_document, document)

    heading = linters.find { |l| l[:key] == :heading_structure }
    assert_equal :amber, heading[:status]
    assert_equal "missing_h1", heading[:code]
  end

  test "seo report flags duplicate title tags" do
    html = "<html><head><title>A</title><title>B</title></head><body><h1>A</h1></body></html>"
    document = Kubik::Reporting::RenderedDocument.new(html)
    report = Kubik::Reporting::SeoReport.new(examples(:one), host: "https://example.test")
    linters = report.send(:linters_from_document, document)

    markup = linters.find { |l| l[:key] == :title_markup }
    assert_equal :red, markup[:status]
    assert_equal "duplicate_title_tag", markup[:code]
  end

  test "seo report flags broken internal links" do
    html = '<html><head><title>T</title></head><body><h1>T</h1><a href="/missing">x</a></body></html>'
    document = Kubik::Reporting::RenderedDocument.new(html)

    checker = Class.new do
      def self.check(hrefs, host:)
        [{ href: "/missing", reason: "404" }]
      end
    end

    broken = Kubik::Reporting::DocumentSeoChecks.evaluate_broken_links(
      document.nokogiri_document,
      host: "https://example.test",
      checker: checker
    )
    assert_equal :red, broken[:status]
    assert_equal "broken_link", broken[:code]
  end
end
