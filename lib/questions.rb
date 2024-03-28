require "json"

class QuestionsDataSource < Nanoc::DataSource
  identifier :questions

  class Question < Struct.new(
    :answers,
    :body_markdown,
    :creation_date,
    :migrated_url,
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
  end

  def up
    @ros_questions = JSON.load(File.read('answers/ros_unexported_se_dump.json'))["Questions"] +
      JSON.load(File.read('answers/ros_se_dump.json'))["Questions"]

    @gz_questions = JSON.load(File.read('answers/gazebosim_unexported_se_dump.json'))["Questions"] +
      JSON.load(File.read('answers/gazebo_se_dump.json'))["Questions"]


    @ros_migration_map = Hash.new
    JSON.load(File.read('answers/ros-to-robotics.json'))["Posts"].each do |post|
      @ros_migration_map[post["OriginalPostID"]] = post["NewUrl"]
    end

    @gz_migration_map = Hash.new
    JSON.load(File.read('answers/gazebo-to-robotics.json'))["Posts"].each do |post|
      @gz_migration_map[post["OriginalPostID"]] = post["NewUrl"]
    end
  end

  def items
    @gz_questions.map do |question|
      q = Question.from_json question
      q.site = 'Gazebo Answers'
      q.migrated_url = @gz_migration_map[q.original_post_id]
      new_item(
        q.body_markdown,
        q.attributes,
        Nanoc::Identifier.new("/gz/question/#{q.original_post_id}.md")
      )
    end + @ros_questions.map do |question|
      q = Question.from_json question
      q.site = 'ROS Answers'
      q.migrated_url = @ros_migration_map[q.original_post_id]
      new_item(
        q.body_markdown,
        q.attributes,
        Nanoc::Identifier.new("/ros/question/#{q.original_post_id}.md")
      )
    end
  end
end
