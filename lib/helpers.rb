module PageTitleHelper
  def page_title_for item

    if item[:site].nil?
      "#{item[:title]} - ROS and Gazebo Answers Archive"
    else
    "#{item[:title]} - #{item[:site]}"
    end
  end
end

use_helper Nanoc::Helpers::Rendering
use_helper PageTitleHelper
