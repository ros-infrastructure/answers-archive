module PageTitleHelper
  def page_title_for item

    if item[:site].nil?
      "#{item[:title]} - ROS and Gazebo Answers Archive"
    else
      "#{item[:title]} - #{item[:site].title}"
    end
  end
end

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

  def pretty_date date
    date.strftime("%F %T UTC")
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

use_helper Nanoc::Helpers::Rendering
use_helper PageTitleHelper
use_helper QuestionsHelper
use_helper MigratedPostsHelper
