require "json"

module QuestionData
  Config = Struct.new(
    :data_path,
    :max_per_site,
    :only_answered,
    :only_migrated,
    :only_commented,
    keyword_init: true
  )

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

  class DataReader
    SITE_IDS = ["ros", "gz"]

    def initialize config
      @config = case config
                when Config
                  config
                when Hash
                  Config.new(*config)
                end
      raise ArgumentError.new("data_path must be specified to read question data") unless @config.data_path
      @data_path = File.expand_path(@config.data_path)
    end

    # Read data for site objects which stores the name of the site (ROS or
    # Gazebo Answers) and the migration map between that site's posts and RSE.
    def sites
      return @sites if defined?(@sites)

      @sites = SITE_IDS.map do |id|
        migration_map = Hash.new
        JSON.load_file(File.join(@data_path, "#{id}-to-robotics.json"))["Posts"].each do |post|
          migration_map[post["OriginalPostID"]] = post["NewUrl"]
        end
        title = case id
                when "gz"
                  "Gazebo Answers"
                when "ros"
                  "ROS Answers"
                end
        Site.new(id: id, title: title, migration_map: migration_map)
      end
    end

    def questions
      return @questions if defined?(@questions)
      @questions = Array.new
      sites.each do |site|
        @questions += read_site_questions site
      end

      return @questions
    end

    # These methods are meant to help populate data internally rather than be
    # part of this class's interface.
    private
    def read_site_questions site
      site_questions = (
        JSON.load_file(File.join(@data_path, "#{site.id}_unexported_se_dump.json"))["Questions"] +
        JSON.load_file(File.join(@data_path, "#{site.id}_se_dump.json"))["Questions"]
      )
      site_questions = site_questions.select do |json|
        site.migration_map.has_key? json["OriginalPostID"]
      end if @config.only_migrated

      site_questions = site_questions.select do |json|
        json["Answers"].size > 0
      end if @config.only_answered

      site_questions = site_questions.select do |json|
        json["BodyMarkdown"] =~ /### Original comments/
      end if @config.only_commented
      site_questions = site_questions.take(@config.max_per_site) if @config.max_per_site

      return site_questions.map do |json|
        Question.from_json(json).tap do |q|
          q.site = site
        end
      end
    end
  end
end
