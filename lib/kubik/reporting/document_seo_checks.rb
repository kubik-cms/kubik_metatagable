# frozen_string_literal: true

module Kubik
  module Reporting
    module DocumentSeoChecks
      module_function

      def evaluate_title_markup(doc)
        titles = doc.css("title")
        if titles.size > 1
          return linter_issue(
            :red,
            "Page has #{titles.size} <title> elements (expected one)",
            code: "duplicate_title_tag"
          )
        end

        descriptions = doc.css("meta[name='description']")
        if descriptions.size > 1
          return linter_issue(
            :amber,
            "Page has #{descriptions.size} meta description tags (expected one)",
            code: "duplicate_meta_description"
          )
        end

        :ok
      end

      def evaluate_heading_structure(doc)
        h1_count = doc.css("h1").size
        if h1_count.zero?
          return linter_issue(:amber, "Document has no h1 heading", code: "missing_h1")
        end
        if h1_count > 1
          return linter_issue(:amber, "Document has #{h1_count} h1 headings (expected one)", code: "multiple_h1")
        end

        levels = doc.css("h1, h2, h3, h4, h5, h6").map { |node| node.name[1].to_i }
        prev = nil
        levels.each do |level|
          if prev && level > prev + 1
            return linter_issue(
              :amber,
              "Heading level jumps from h#{prev} to h#{level}",
              code: "heading_level_skip"
            )
          end
          prev = level
        end

        :ok
      end

      def evaluate_image_alt(doc)
        missing = doc.css("img").reject { |img| img.has_attribute?("alt") }
        return :ok if missing.empty?

        count = missing.size
        linter_issue(
          :amber,
          "#{count} image#{'s' if count != 1} missing alt text",
          code: "img_missing_alt"
        )
      end

      def evaluate_broken_links(doc, host:, checker: LinkChecker)
        unless checker.enabled?
          return linter_issue(:unknown, "Link checking is disabled", code: "link_check_disabled")
        end

        empty_links = doc.css("a").count { |node| node["href"].nil? || node["href"].strip.empty? }
        if empty_links.positive?
          return linter_issue(
            :red,
            "#{empty_links} link#{'s' if empty_links != 1} with an empty href",
            code: "empty_link"
          )
        end

        hrefs = doc.css("a[href]").filter_map { |node| node["href"]&.strip }.reject(&:blank?)
        return :ok if hrefs.empty?

        internal_hrefs = hrefs.select { |href| internal_href?(href, host) }
        return :ok if internal_hrefs.empty?

        broken = checker.check(internal_hrefs, host: host)
        return :ok if broken.empty?

        sample = broken.first(3).map { |entry| entry[:href] }.join(", ")
        extra = broken.size > 3 ? " (+#{broken.size - 3} more)" : ""
        linter_issue(
          :red,
          "#{broken.size} broken link#{'s' if broken.size != 1}: #{sample}#{extra}",
          code: "broken_link"
        )
      end

      def internal_href?(href, host)
        return true if href.start_with?("/")
        return false if href.start_with?("#")

        base = URI.parse(host.to_s)
        uri = URI.parse(href)
        return true if uri.host.nil?

        uri.host == base.host
      rescue URI::Error
        false
      end

      def linter_issue(status, message, code:)
        { status: status, message: message, code: code }
      end
    end
  end
end
