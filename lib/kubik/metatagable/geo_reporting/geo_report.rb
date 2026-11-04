# frozen_string_literal: true

module Kubik
  module Reporting
    class GeoReport
      LINTERS = [
        { key: :ai_indexing, label: "AI indexing" },
        { key: :ai_snippets, label: "AI snippets" },
        { key: :search_visibility, label: "Search visibility" },
        { key: :structured_data, label: "Structured data" },
        { key: :schema_type, label: "Page schema type" },
        { key: :article_facts, label: "Article facts" },
        { key: :page_language, label: "Page language" },
        { key: :main_content, label: "Main content" },
        { key: :faq_schema, label: "FAQ markup" }
      ].freeze

      def self.for(record, host:)
        new(record, host: host).run
      end

      def initialize(record, host:)
        @record = record
        @host = host
        @findings = []
        @linters = []
      end

      def run
        document = RenderedDocument.for(@record)
        @linters = if document.render_error.present?
                     linters_for_render_error(document.render_error)
                   elsif document.available?
                     linters_from_document(document)
                   else
                     linters_from_meta_tag
                   end

        @findings = linters_to_findings(@linters)

        {
          status: aggregate_status,
          label: HtmlValidationReport.label_for(aggregate_status),
          findings: @findings,
          linters: @linters
        }
      end

      private

      def linters_from_document(document)
        doc = document.nokogiri_document
        expect_json_ld = expect_json_ld?
        published = @record.respond_to?(:published?) && @record.published?

        [
          evaluate_ai_indexing(document, doc),
          document_check_result(:ai_snippets, DocumentGeoChecks.evaluate_ai_snippets(doc)),
          document_check_result(:search_visibility, DocumentGeoChecks.evaluate_search_visibility(doc)),
          evaluate_structured_data(doc, expect_json_ld: expect_json_ld),
          evaluate_schema_type(doc, expect_json_ld: expect_json_ld),
          evaluate_article_facts(doc, expect_json_ld: expect_json_ld),
          document_check_result(:page_language, DocumentGeoChecks.evaluate_page_language(doc)),
          document_check_result(:main_content, DocumentGeoChecks.evaluate_main_content(doc, published: published)),
          document_check_result(:faq_schema, DocumentGeoChecks.evaluate_faq_schema(doc))
        ]
      end

      def linters_from_meta_tag
        meta = @record.meta_tag
        unless meta
          return LINTERS.map do |definition|
            linter_result(definition[:key], :red, "No SEO meta tag record", code: "missing_meta_tag")
          end
        end

        [
          evaluate_ai_indexing_from_meta(meta),
          evaluate_ai_snippets_from_meta(meta),
          evaluate_search_visibility_from_meta(meta),
          structured_data_linter_from_meta(meta),
          linter_result(:schema_type, :unknown, "Requires rendered page to verify"),
          linter_result(:article_facts, :unknown, "Requires rendered page to verify"),
          linter_result(:page_language, :unknown, "Requires rendered page to verify"),
          linter_result(:main_content, :unknown, "Requires rendered page to verify"),
          linter_result(:faq_schema, :unknown, "Requires rendered page to verify")
        ]
      end

      def linters_for_render_error(error)
        unknown = "Could not check — page did not render"
        [
          linter_result(:ai_indexing, :red, "Page could not be rendered: #{error}", code: "render_failed"),
          linter_result(:ai_snippets, :unknown, unknown),
          linter_result(:search_visibility, :unknown, unknown),
          linter_result(:structured_data, :unknown, unknown),
          linter_result(:schema_type, :unknown, unknown),
          linter_result(:article_facts, :unknown, unknown),
          linter_result(:page_language, :unknown, unknown),
          linter_result(:main_content, :unknown, unknown),
          linter_result(:faq_schema, :unknown, unknown)
        ]
      end

      def evaluate_ai_indexing(_document, doc)
        doc_result = DocumentGeoChecks.evaluate_ai_indexing(doc)
        return document_check_result(:ai_indexing, doc_result) if doc_result != :ok

        meta = @record.meta_tag
        if meta&.respond_to?(:block_ai_crawlers) && meta.block_ai_crawlers?
          return linter_result(:ai_indexing, :amber, "AI crawlers blocked for this page", code: "ai_blocked")
        end

        linter_result(:ai_indexing, :green, nil)
      end

      def evaluate_structured_data(doc, expect_json_ld:)
        unless structured_data_applicable?
          return linter_result(:structured_data, :unknown, "Structured data gem not installed")
        end

        document_check_result(
          :structured_data,
          DocumentGeoChecks.evaluate_structured_data(doc, expect_json_ld: expect_json_ld)
        )
      end

      def evaluate_schema_type(doc, expect_json_ld:)
        unless structured_data_applicable?
          return linter_result(:schema_type, :unknown, "Structured data gem not installed")
        end

        document_check_result(
          :schema_type,
          DocumentGeoChecks.evaluate_schema_type(doc, record: @record, expect_json_ld: expect_json_ld)
        )
      end

      def evaluate_article_facts(doc, expect_json_ld:)
        unless structured_data_applicable?
          return linter_result(:article_facts, :unknown, "Structured data gem not installed")
        end

        document_check_result(
          :article_facts,
          DocumentGeoChecks.evaluate_article_facts(doc, record: @record, expect_json_ld: expect_json_ld)
        )
      end

      def evaluate_ai_indexing_from_meta(meta)
        if meta.respond_to?(:block_ai_crawlers) && meta.block_ai_crawlers?
          return linter_result(:ai_indexing, :amber, "AI crawlers blocked for this page", code: "ai_blocked")
        end

        if meta.respond_to?(:robots_meta_content)
          directives = DocumentGeoChecks.parse_robots_directives(meta.robots_meta_content)
          if directives.intersect?(%w[noai noimageai])
            return linter_result(:ai_indexing, :amber, "AI crawlers blocked for this page", code: "ai_blocked")
          end
        end

        linter_result(:ai_indexing, :unknown, "Requires rendered page to verify")
      end

      def evaluate_ai_snippets_from_meta(meta)
        if meta.respond_to?(:robots_nosnippet) && meta.robots_nosnippet?
          return linter_result(:ai_snippets, :amber, "Robots meta limits reuse for AI snippets (nosnippet)", code: "ai_snippet_limited")
        end
        if meta.respond_to?(:robots_noarchive) && meta.robots_noarchive?
          return linter_result(:ai_snippets, :amber, "Robots meta limits reuse for AI snippets (noarchive)", code: "ai_snippet_limited")
        end

        linter_result(:ai_snippets, :unknown, "Requires rendered page to verify")
      end

      def evaluate_search_visibility_from_meta(meta)
        if meta.respond_to?(:robots_noindex) && meta.robots_noindex?
          return linter_result(
            :search_visibility,
            :amber,
            "Page is noindex — also limits generative discovery",
            code: "noindex"
          )
        end

        linter_result(:search_visibility, :unknown, "Requires rendered page to verify")
      end

      def structured_data_linter_from_meta(meta)
        unless structured_data_applicable?
          return linter_result(:structured_data, :unknown, "Structured data gem not installed")
        end

        if expect_json_ld?
          linter_result(:structured_data, :unknown, "Requires rendered page to verify")
        else
          linter_result(:structured_data, :green, nil)
        end
      end

      def document_check_result(key, result)
        return linter_result(key, :green, nil) if result == :ok

        linter_result(key, result[:status], result[:message], code: result[:code])
      end

      def linter_result(key, status, message, code: nil)
        definition = LINTERS.find { |entry| entry[:key] == key }
        {
          key: key,
          label: definition[:label],
          status: status,
          message: message,
          code: code
        }
      end

      def linters_to_findings(linters)
        linters.filter_map do |entry|
          next if entry[:status] == :green || entry[:status] == :unknown

          severity = entry[:status] == :red ? :error : :warning
          { severity: severity, code: entry[:code], message: entry[:message] }
        end
      end

      def structured_data_applicable?
        defined?(KubikStructuredData) && KubikStructuredData.respond_to?(:registry)
      end

      def expect_json_ld?
        return false unless structured_data_applicable?

        meta = @record.meta_tag
        return true unless meta&.has_attribute?(:robots_noindex)

        !meta.robots_noindex?
      end

      def aggregate_status
        from_findings = AggregateStatus.from_findings(@findings)
        return from_findings if from_findings != :green

        linter_statuses = @linters.map { |entry| entry[:status] }
        return :unknown if linter_statuses.any?(:unknown) && linter_statuses.none?(:green)

        :green
      end
    end
  end
end
