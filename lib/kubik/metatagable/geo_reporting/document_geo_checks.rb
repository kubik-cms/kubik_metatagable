# frozen_string_literal: true

module Kubik
  module Reporting
    module DocumentGeoChecks
      MIN_BODY_WORDS = 80
      ARTICLE_SCHEMA_TYPES = %w[Article NewsArticle].freeze

      module_function

      def evaluate_ai_indexing(doc)
        directives = robots_directives_from_doc(doc)
        if directives.intersect?(%w[noai noimageai])
          return linter_issue(
            :amber,
            "Page blocks AI crawlers (noai or noimageai in robots meta)",
            code: "ai_blocked"
          )
        end

        :ok
      end

      def evaluate_ai_snippets(doc)
        directives = robots_directives_from_doc(doc)
        flags = []
        flags << "nosnippet" if directives.include?("nosnippet")
        flags << "noarchive" if directives.include?("noarchive")
        return :ok if flags.empty?

        linter_issue(
          :amber,
          "Robots meta limits reuse for AI snippets (#{flags.join(', ')})",
          code: "ai_snippet_limited"
        )
      end

      def evaluate_search_visibility(doc)
        directives = robots_directives_from_doc(doc)
        if directives.include?("noindex")
          return linter_issue(
            :amber,
            "Page is noindex — also limits generative discovery",
            code: "noindex"
          )
        end

        :ok
      end

      def evaluate_structured_data(doc, expect_json_ld:)
        return :ok unless expect_json_ld

        nodes, invalid = parse_json_ld_nodes(doc)
        if invalid
          return linter_issue(:red, "Invalid JSON-LD on page", code: "invalid_json_ld")
        end

        schema_nodes = schema_org_nodes(nodes)
        if schema_nodes.empty?
          return linter_issue(:amber, "No schema.org JSON-LD found in rendered page", code: "missing_structured_data")
        end

        :ok
      end

      def evaluate_schema_type(doc, record:, expect_json_ld:)
        return :ok unless expect_json_ld
        return :ok unless structured_data_registry_available?

        profile = KubikStructuredData.registry.profile_for(record)
        return :ok unless profile

        expected_type = schema_type_label(profile.schema_type)
        types = collect_json_ld_types(doc)
        return :ok if types.empty?

        if types.include?(expected_type)
          :ok
        else
          linter_issue(
            :amber,
            "Expected JSON-LD @type #{expected_type}, found #{types.uniq.join(', ')}",
            code: "schema_type_mismatch"
          )
        end
      end

      def evaluate_article_facts(doc, record:, expect_json_ld:)
        return :ok unless expect_json_ld
        return :ok unless structured_data_registry_available?

        profile = KubikStructuredData.registry.profile_for(record)
        expected_type = profile ? schema_type_label(profile.schema_type) : nil

        nodes, = parse_json_ld_nodes(doc)
        schema_nodes = schema_org_nodes(nodes)
        article_nodes = schema_nodes.select do |node|
          ARTICLE_SCHEMA_TYPES.include?(json_ld_type_value(node["@type"]))
        end

        return :ok if article_nodes.empty? && !ARTICLE_SCHEMA_TYPES.include?(expected_type)

        article_nodes = article_nodes.presence || schema_nodes.select do |node|
          json_ld_type_value(node["@type"]) == expected_type
        end

        missing = article_nodes.flat_map { |node| article_fact_gaps(node) }.uniq
        return :ok if missing.empty?

        linter_issue(
          :amber,
          "Article JSON-LD missing #{missing.join(' and ')}",
          code: "article_facts_incomplete"
        )
      end

      def evaluate_page_language(doc)
        lang = doc.at("html")&.[]("lang")&.strip
        if lang.blank?
          return linter_issue(:amber, "Missing html lang attribute", code: "missing_lang")
        end

        :ok
      end

      def evaluate_main_content(doc, published:)
        main = doc.at("main")
        word_count = visible_word_count(main || doc.at("body"))
        return :ok if main.present?
        return :ok if word_count >= MIN_BODY_WORDS
        return :ok unless published

        linter_issue(
          :amber,
          "Thin page body (#{word_count} words, expected at least #{MIN_BODY_WORDS} or a main element)",
          code: "thin_content"
        )
      end

      def evaluate_faq_schema(doc)
        return :ok unless faq_markup_present?(doc)

        types = collect_json_ld_types(doc)
        if types.include?("FAQPage")
          :ok
        else
          linter_issue(
            :amber,
            "FAQ content detected but no FAQPage JSON-LD",
            code: "missing_faq_schema"
          )
        end
      end

      def robots_directives_from_doc(doc)
        content = doc.at("meta[name='robots']")&.[]("content")
        parse_robots_directives(content)
      end

      def parse_robots_directives(content)
        content.to_s.downcase.split(/[,\s]+/).map(&:strip).reject(&:blank?)
      end

      def parse_json_ld_nodes(doc)
        invalid = false
        nodes = []
        doc.css('script[type="application/ld+json"]').each do |script|
          text = script.text.strip
          next if text.blank?

          begin
            data = JSON.parse(text)
          rescue JSON::ParserError
            invalid = true
            next
          end
          nodes.concat(flatten_json_ld(data))
        end
        [nodes, invalid]
      end

      def flatten_json_ld(data)
        case data
        when Array
          data.flat_map { |entry| flatten_json_ld(entry) }
        when Hash
          if data["@graph"]
            flatten_json_ld(data["@graph"])
          else
            [data]
          end
        else
          []
        end
      end

      def schema_org_nodes(nodes)
        nodes.select do |node|
          node.is_a?(Hash) && node["@context"].to_s.include?("schema.org")
        end
      end

      def collect_json_ld_types(doc)
        nodes, = parse_json_ld_nodes(doc)
        schema_org_nodes(nodes).flat_map { |node| json_ld_type_value(node["@type"]) }.compact
      end

      def json_ld_type_value(type)
        case type
        when Array
          type.map { |entry| json_ld_type_value(entry) }.compact.first
        when String
          type.split("::").last.split("/").last
        end
      end

      def faq_markup_present?(doc)
        return true if doc.css("[data-kubik-faq]").any?

        doc.css("details summary").size >= 2
      end

      def visible_word_count(node)
        return 0 unless node

        node.text.to_s.split(/\s+/).count(&:present?)
      end

      def structured_data_registry_available?
        defined?(KubikStructuredData) && KubikStructuredData.respond_to?(:registry)
      end

      def schema_type_label(schema_type)
        return schema_type.name.demodulize if schema_type.is_a?(Class)

        schema_type.to_s.split("::").last
      end

      def article_fact_gaps(node)
        gaps = []
        gaps << "datePublished" if node["datePublished"].blank?
        gaps << "author or publisher" if node["author"].blank? && node["publisher"].blank?
        gaps
      end

      def linter_issue(status, message, code:)
        { status: status, message: message, code: code }
      end
    end
  end
end
