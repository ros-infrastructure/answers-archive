require "json"

class Question < Struct.new(
  :answers,
  :body_markdown,
  :creation_date,
  :original_post_id,
  :original_post_url,
  :owner_display_name,
  :site,
  :tags,
  :title,
  :upvote_count,
  keyword_init: true
)

  def self.from_json json
    self.new(
      original_post_id: json['OriginalPostID'],
      title: json['Title'],
      body_markdown: json['BodyMarkdown'],
      owner_display_name: json['OwnerDisplayName'],
      tags: json["Tags"].split(","),
      creation_date: json['CreationDate'], # TODO PARSE IT?
      upvote_count: json['UpvoteCount'],
      original_post_url: json['OriginalPostURL'],
      answers: json['Answers'].map{|answer| Answer.from_json answer},
    )
  end

  def attributes
    @attributes ||= self.to_h
  end

  def migrated_url
    self.site.migration_map[self.original_post_id]
  end

  def nanoc_identifier
    @nanoc_identifier ||= Nanoc::Identifier.new(
      "/#{self.site.id}/question/#{self.original_post_id}.md"
    )
  end
end

class Answer < Struct.new(
  :accepted?,
  :body_markdown,
  :creation_date,
  :original_post_id,
  :owner_display_name,
  :upvote_count,
  keyword_init: true
)
  def self.from_json json
    self.new(
      original_post_id: json["OriginalPostID"],
      owner_display_name: json["OwnerDisplayName"],
      creation_date: json["CreationDate"],
      body_markdown: json["BodyMarkdown"],
      accepted?: json["Accepted"],
      upvote_count: json["UpvoteCount"],
    )
  end

  def attributes
    self.to_h
  end

  def nanoc_identifier
    @nanoc_identifier ||= Nanoc::Identifier.new(
      "/answer/#{self.original_post_id}.md"
    )
  end
end

class Site < Struct.new(:id, :title, :migration_map, keyword_init: true)
end

class QuestionsDataSource < Nanoc::DataSource
  identifier :questions

  def up
    ros_migration_map = Hash.new
    JSON.load(File.read('answers/ros-to-robotics.json'))["Posts"].each do |post|
      ros_migration_map[post["OriginalPostID"]] = post["NewUrl"]
    end
    ros_site = Site.new(id: "ros", title: "ROS Answers", migration_map: ros_migration_map)

    gz_migration_map = Hash.new
    JSON.load(File.read('answers/gazebo-to-robotics.json'))["Posts"].each do |post|
      gz_migration_map[post["OriginalPostID"]] = post["NewUrl"]
    end
    gz_site = Site.new(id: "gz", title: "Gazebo Answers", migration_map: gz_migration_map)

    @questions = Array.new

    (JSON.load(File.read('answers/ros_unexported_se_dump.json'))["Questions"] +
     JSON.load(File.read('answers/ros_se_dump.json'))["Questions"]).select{|json|
       json["Answers"].size > 0}.take(10).each do |q_json|
      question = Question.from_json q_json
      question.site = ros_site
      @questions << question
    end

   (JSON.load(File.read('answers/gazebosim_unexported_se_dump.json'))["Questions"] +
    JSON.load(File.read('answers/gazebo_se_dump.json'))["Questions"]).select{|json|
      json["Answers"].size > 0}.take(10).each do |q_json|
      question = Question.from_json q_json
      question.site = gz_site
      @questions << question
    end
  end

  def items
    return @items if defined? @items

    @items = Array.new
    @questions.each do |question|
      @items << new_item(
        question.body_markdown,
        question.attributes,
        question.nanoc_identifier
      )
      if question.answers
        question.answers.each do |answer|
          @items << new_item(
            answer.body_markdown,
            answer.attributes,
            Nanoc::Identifier.new(question.nanoc_identifier.without_ext + answer.nanoc_identifier)
          )
        end
      end
    end
    @items
  end
end
