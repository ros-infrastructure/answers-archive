require "json"
require "yaml"

# This is a hack anyway but I still wish I could read the existing nanoc config
# instead of re-reading the YAML. But whatever
QuestionsConfig = Struct.new(:max_per_site, :only_answered, :only_migrated)
CONFIG = QuestionsConfig.new
if ENV["XTEST_ANSWERS_DEBUG"]
  config = YAML.load_file("nanoc.yaml")["data_sources"].select{|ds| ds["type"] == "questions"}.first["xtest"]
  CONFIG.max_per_site = config["max_per_site"]
  CONFIG.only_answered = config["only_answered"]
  CONFIG.only_migrated = config["only_migrated"]
end


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
    return @attributes if defined?(@attributes)
    @attributes = self.to_h.tap do |h|
      h[:migrated_url] = self.migrated_url
    end
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

    ros_questions = (JSON.load(File.read('answers/ros_unexported_se_dump.json'))["Questions"] +
                     JSON.load(File.read('answers/ros_se_dump.json'))["Questions"])
    if CONFIG.only_migrated
      ros_questions = ros_questions.select { |json| ros_migration_map.has_key? json["OriginalPostID"] }
    end
    if CONFIG.only_answered
      ros_questions = ros_questions.select { |json| json["Answers"].size > 0 }
    end
    if CONFIG.max_per_site
      ros_questions = ros_questions.take(CONFIG.max_per_site)
    end

    ros_questions.each do |q_json|
      question = Question.from_json q_json
      question.site = ros_site
      @questions << question
    end

   gz_questions = (JSON.load(File.read('answers/gazebosim_unexported_se_dump.json'))["Questions"] +
                   JSON.load(File.read('answers/gazebo_se_dump.json'))["Questions"])
    if CONFIG.only_migrated
      gz_questions = gz_questions.select { |json| gz_migration_map.has_key? json["OriginalPostID"] }
    end
   if CONFIG.only_answered
     gz_questions = gz_questions.select { |json| json["Answers"].size > 0 }
   end
   if CONFIG.max_per_site
     gz_questions = gz_questions.take(CONFIG.max_per_site)
   end

    gz_questions.each do |q_json|
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
