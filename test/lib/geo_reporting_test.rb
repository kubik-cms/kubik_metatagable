# frozen_string_literal: true

require "test_helper"

class KubikGeoReportingTest < ActiveSupport::TestCase
  def healthy_geo_html
    words = Array.new(85) { "word" }.join(" ")
    <<~HTML
      <html lang="en"><head>
        <meta name="robots" content="index, follow">
        <script type="application/ld+json">
          {"@context":"https://schema.org","@type":"WebPage","name":"Title","url":"https://example.test/page"}
        </script>
      </head><body><main><h1>Title</h1><p>#{words}</p></main></body></html>
    HTML
  end

  test "geo report lists all linters with green status when page is healthy" do
    document = Kubik::Reporting::RenderedDocument.new(healthy_geo_html)
    report = Kubik::Reporting::GeoReport.new(examples(:one), host: "https://example.test")
    linters = report.send(:linters_from_document, document)

    assert_equal Kubik::Reporting::GeoReport::LINTERS.size, linters.size
    core_keys = %i[ai_indexing ai_snippets search_visibility page_language main_content faq_schema]
    core = linters.select { |l| core_keys.include?(l[:key]) }
    assert core.all? { |l| l[:status] == :green }
  end

  test "geo report flags noai in rendered robots meta" do
    html = healthy_geo_html.sub("index, follow", "noai, noimageai")
    document = Kubik::Reporting::RenderedDocument.new(html)
    report = Kubik::Reporting::GeoReport.new(examples(:one), host: "https://example.test")
    linters = report.send(:linters_from_document, document)

    ai = linters.find { |l| l[:key] == :ai_indexing }
    assert_equal :amber, ai[:status]
    assert_equal "ai_blocked", ai[:code]
  end

  test "geo report flags missing lang" do
    html = healthy_geo_html.sub('<html lang="en">', "<html>")
    document = Kubik::Reporting::RenderedDocument.new(html)
    report = Kubik::Reporting::GeoReport.new(examples(:one), host: "https://example.test")
    linters = report.send(:linters_from_document, document)

    lang = linters.find { |l| l[:key] == :page_language }
    assert_equal :amber, lang[:status]
    assert_equal "missing_lang", lang[:code]
  end

  test "geo report flags faq markup without faqpage schema" do
    html = healthy_geo_html.sub("</main>", "<details><summary>Q1</summary><p>A1</p></details><details><summary>Q2</summary><p>A2</p></details></main>")
    document = Kubik::Reporting::RenderedDocument.new(html)
    report = Kubik::Reporting::GeoReport.new(examples(:one), host: "https://example.test")
    linters = report.send(:linters_from_document, document)

    faq = linters.find { |l| l[:key] == :faq_schema }
    assert_equal :amber, faq[:status]
    assert_equal "missing_faq_schema", faq[:code]
  end

  test "reporting summary includes geo key" do
    summary = Kubik::Reporting.summary_for(examples(:one), host: "https://example.test")
    assert summary.key?(:geo)
    assert summary[:geo].key?(:linters)
  end

  test "summary items include geo indicator" do
    assert Kubik::ReportingAdminHelper.summary_items.any? { |item| item[:key] == :geo }
  end
end
