# frozen_string_literal: true

require "test_helper"

class SocialMetaImagesTest < ActiveSupport::TestCase
  test "derivative_for og uses social_og by default" do
    assert_equal :social_og, KubikMetatagable::SocialMetaImages.derivative_for(platform: :og)
  end

  test "derivative_for twitter uses large card crop by default" do
    meta_tag = Kubik::MetaTag.new(twitter_card_type: "summary_large_image")
    assert_equal :social_twitter_large,
                 KubikMetatagable::SocialMetaImages.derivative_for(platform: :twitter, meta_tag: meta_tag)
  end

  test "derivative_for twitter summary uses small crop" do
    meta_tag = Kubik::MetaTag.new(twitter_card_type: "summary")
    assert_equal :social_twitter_small,
                 KubikMetatagable::SocialMetaImages.derivative_for(platform: :twitter, meta_tag: meta_tag)
  end

  test "social_image_derivative config overrides platform defaults" do
    KubikMetatagable.configure { |c| c.social_image_derivative = :content_1200 }
    assert_equal :content_1200, KubikMetatagable::SocialMetaImages.derivative_for(platform: :twitter)
  ensure
    KubikMetatagable.configure { |c| c.social_image_derivative = nil }
  end
end
