# frozen_string_literal: true

require "test_helper"

class DiscoverabilityTest < ActiveSupport::TestCase
  test "bot catalog loads entries from ai-crawler-index" do
    entries = Kubik::Discoverability::BotCatalog.entries
    assert entries.size.positive?
    assert entries.any? { |e| e.token == "GPTBot" || e.label.include?("GPT") }
  end

  test "robots txt builder blocks admin paths by default" do
    body = Kubik::Discoverability::RobotsTxtBuilder.generate({})
    assert_includes body, "Disallow: /admin/"
  end

  test "policy resolver normalizes stances" do
    assert_equal :block, Kubik::Discoverability::PolicyResolver.normalize_stance("block")
    assert_equal :inherit, Kubik::Discoverability::PolicyResolver.normalize_stance(nil)
  end

  test "llms txt builder includes body and optional policy summary" do
    body = Kubik::Discoverability::LlmsTxtBuilder.render(
      {
        "llms_txt_body" => "# Example",
        "llms_txt_include_policy_summary" => false
      }
    )
    assert_includes body, "# Example"
  end
end
