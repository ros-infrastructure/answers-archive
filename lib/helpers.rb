require "redcarpet"

module QuestionsHelper
  def answers_for item
    items.find_all "#{item.identifier.without_ext}/answer/*"
  end

  def comments_for item
    items.find_all "#{item.identifier.without_ext}/comment/*"
  end

  def questions_for_site site
    items.find_all "/questions/#{site}/question/*"
  end

  def pretty_date date_str
    DateTime.parse(date_str).strftime("%F %T UTC")
  end
end

module MigratedPostsHelper
  def migrated_posts
    items.select do |item|
      item[:migrated_url]
    end
  end

  def migrated_ros_posts
    migrated_posts.select do |item|
      item[:site].id == "ros"
    end
  end

  def migrated_gz_posts
    migrated_posts.select do |item|
      item[:site].id == "gz"
    end
  end
end

module MarkdownHelper
  RENDERER = Redcarpet::Markdown.new(
    Redcarpet::Render::HTML,
    no_intra_emphasis: true,
    autolink: true,
  )

  def render_markdown md_str
    RENDERER.render(md_str)
  end
end

use_helper Nanoc::Helpers::Rendering
use_helper QuestionsHelper
use_helper MigratedPostsHelper
use_helper MarkdownHelper
