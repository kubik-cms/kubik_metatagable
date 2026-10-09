# frozen_string_literal: true

module Kubik
  module Reporting
    class SeoReport
      TITLE_MAX = 60
      DESCRIPTION_MAX = 160
      DESCRIPTION_MIN = 50

      LINTERS = [
        { key: :title, label: "Page title" },
        { key: :title_markup, label: "Title & description tags" },
        { key: :meta_description, label: "Meta description" },
        { key: :canonical, label: "Canonical link" },
        { key: :indexing, label: "Search indexing" },
        { key: :heading_structure, label: "Heading structure" },
        { key: :image_alt, label: "Image alt text" },
        { key: :broken_links, label: "Page links" }
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
        [
          evaluate_title(document.title),
          evaluate_title_markup(doc),
          evaluate_meta_description(document.meta_name("description")),
          evaluate_canonical(document.link_rel("canonical")),
          evaluate_indexing(document.meta_name("robots")),
          evaluate_heading_structure(doc),
          evaluate_image_alt(doc),
          evaluate_broken_links(doc)
        ]
      end

      def linters_from_meta_tag
        meta = @record.meta_tag
        unless meta
          return LINTERS.map do |definition|
            linter_result(definition[:key], :red, "No SEO meta tag record", code: "missing_meta_tag")
          end
        end

        title = meta.title_tag.presence || default_title
        description = meta.meta_description.presence

        [
          evaluate_title(title),
          linter_result(:title_markup, :unknown, "Requires rendered page to verify"),
          evaluate_meta_description(description),
          evaluate_canonical_from_meta(meta),
          evaluate_indexing_from_meta(meta),
          linter_result(:heading_structure, :unknown, "Requires rendered page to verify"),
          linter_result(:image_alt, :unknown, "Requires rendered page to verify"),
          linter_result(:broken_links, :unknown, "Requires rendered page to verify")
        ]
      end

      def linters_for_render_error(error)
        unknown = "Could not check — page did not render"
        [
          linter_result(:title, :red, "Page could not be rendered: #{error}", code: "render_failed"),
          linter_result(:title_markup, :unknown, unknown),
          linter_result(:meta_description, :unknown, unknown),
          linter_result(:canonical, :unknown, unknown),
          linter_result(:indexing, :unknown, unknown),
          linter_result(:heading_structure, :unknown, unknown),
          linter_result(:image_alt, :unknown, unknown),
          linter_result(:broken_links, :unknown, unknown)
        ]
      end

      def evaluate_title(title)
        if title.blank?
          linter_result(:title, :red, "Missing <title> in rendered page", code: "missing_title")
        elsif title.length > TITLE_MAX
          linter_result(:title, :amber, "Title is longer than #{TITLE_MAX} characters", code: "title_long")
        else
          linter_result(:title, :green, nil)
        end
      end

      def evaluate_meta_description(description)
        if description.blank?
          linter_result(:meta_description, :red, "Missing meta description in rendered page", code: "missing_meta_description")
        elsif description.length > DESCRIPTION_MAX
          linter_result(:meta_description, :amber, "Meta description is longer than #{DESCRIPTION_MAX} characters",
                        code: "description_long")
        elsif description.length < DESCRIPTION_MIN
          linter_result(:meta_description, :amber, "Meta description is shorter than #{DESCRIPTION_MIN} characters",
                        code: "description_short")
        else
          linter_result(:meta_description, :green, nil)
        end
      end

      def evaluate_canonical(canonical)
        if canonical.blank?
          linter_result(:canonical, :amber, "Missing canonical link", code: "missing_canonical")
        else
          linter_result(:canonical, :green, nil)
        end
      end

      def evaluate_indexing(robots)
        if robots.to_s.include?("noindex")
          linter_result(:indexing, :amber, "Page is set to noindex", code: "noindex")
        else
          linter_result(:indexing, :green, nil)
        end
      end

      def evaluate_title_markup(doc)
        document_check_result(:title_markup, DocumentSeoChecks.evaluate_title_markup(doc))
      end

      def evaluate_heading_structure(doc)
        document_check_result(:heading_structure, DocumentSeoChecks.evaluate_heading_structure(doc))
      end

      def evaluate_image_alt(doc)
        document_check_result(:image_alt, DocumentSeoChecks.evaluate_image_alt(doc))
      end

      def evaluate_broken_links(doc)
        document_check_result(:broken_links, DocumentSeoChecks.evaluate_broken_links(doc, host: @host))
      end

      def document_check_result(key, result)
        return linter_result(key, :green, nil) if result == :ok

        linter_result(key, result[:status], result[:message], code: result[:code])
      end

      def evaluate_canonical_from_meta(meta)
        if meta.respond_to?(:canonical_url_override) && meta.canonical_url_override.present?
          linter_result(:canonical, :green, nil)
        else
          linter_result(:canonical, :unknown, "Requires rendered page to verify")
        end
      end

      def evaluate_indexing_from_meta(meta)
        if meta.respond_to?(:robots_noindex) && meta.robots_noindex?
          linter_result(:indexing, :amber, "Page is set to noindex", code: "noindex")
        elsif meta.respond_to?(:robots_noindex)
          linter_result(:indexing, :green, nil)
        else
          linter_result(:indexing, :unknown, "Requires rendered page to verify")
        end
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

      def default_title
        return @record.title if @record.respond_to?(:title)

        @record.name if @record.respond_to?(:name)
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
