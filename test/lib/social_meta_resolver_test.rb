# frozen_string_literal: true

require "test_helper"

class SocialMetaResolverTest < ActiveSupport::TestCase
  setup do
    KubikMetatagable.configure do |config|
      config.register_canonical_path("Example") do |record, _routes|
        "/examples/#{record.id}"
      end
    end
  end

  test "resolve merges site title and canonical url" do
    example = examples(:one)
    example.build_meta_tag(title_tag: "Hello", og_title: "OG Hello")
    example.save!

    result = Kubik::Metatagable::SocialMetaResolver.resolve(example, host: "https://example.test")

    assert_equal "https://example.test/examples/#{example.id}", result[:og_url]
    assert_includes result[:title_tag], "Hello"
  end
end
