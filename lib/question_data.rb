require "date"
require "sequel"


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
    :comments,
    :body_markdown,
    :creation_date,
    :original_post_id,
    :original_post_url,
    :owner,
    :site,
    :tags,
    :title,
    :upvote_count,
    keyword_init: true
  )

    def self.from_json json
      owner = UserProfile.find_by_url(json["OwnerProfileUrl"]) ||
        UserProfile.add(
          UserProfile.from_owner_info(json["OwnerProfileUrl"], json["OwnerDisplayName"])
        )

      self.new(
        original_post_id: json["OriginalPostID"],
        title: json["Title"],
        body_markdown: json["BodyMarkdown"],
        owner: owner,
        tags: json["Tags"].split(","),
        creation_date: DateTime.parse(json["CreationDate"]),
        upvote_count: json["UpvoteCount"],
        original_post_url: json["OriginalPostURL"],
        answers: json["Answers"].map{|answer| Answer.from_json answer},
        comments: json["Comments"].map{|comment| Comment.from_json comment},
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
    :owner,
    :upvote_count,
    :comments,
    keyword_init: true
  )
    def self.from_json json
      owner = UserProfile.find_by_url(json["OwnerProfileUrl"]) ||
        UserProfile.add(
          UserProfile.from_owner_info(json["OwnerProfileUrl"], json["OwnerDisplayName"])
        )

      self.new(
        original_post_id: json["OriginalPostID"],
        owner: owner,
        creation_date: DateTime.parse(json["CreationDate"]),
        body_markdown: json["BodyMarkdown"],
        accepted?: json["Accepted"],
        upvote_count: json["UpvoteCount"],
        comments: json["Comments"].map{|comment| Comment.from_json comment},
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

  class Comment < Struct.new(
    :body_markdown,
    :owner,
    :creation_date,
    keyword_init: true
  )

    def self.from_json json
      owner = UserProfile.find_by_url(json["OwnerProfileUrl"]) ||
        UserProfile.add(
          UserProfile.from_owner_info(json["OwnerProfileUrl"], json["OwnerDisplayName"])
        )

      self.new(
        body_markdown: json["BodyMarkdown"],
        owner: owner,
        creation_date: DateTime.parse(json["CreationDate"]),
      )
    end

    def attributes
      self.to_h
    end

    def nanoc_identifier index
      @nanoc_identifier ||= Nanoc::Identifier.new(
        "/comment/#{self.owner.id}-#{index}.md"
      )
    end
  end

  class UserProfile < Struct.new(
    :id,
    :profile_url,
    :site,
    :username,
    :display_name,
    keyword_init: true
  )
    URL_PATTERN = %r{https://([a-z\.]+)/users/(\d+)/([^/]+)/}

    @@all_users ||= Hash.new

    def self.from_owner_info url, display_name
      match_data = url.match(URL_PATTERN)

      domain = match_data[1]
      id = match_data[2].to_i
      username = match_data[3]
      site = Site.find_by_domain domain
      self.new(id: id, username: username, display_name: display_name, profile_url: url, site: site)
    end

    def self.find_by_url url
      require "pry"; binding.pry unless url.match(URL_PATTERN)
      id = url.match(URL_PATTERN)[1].to_i
      @@all_users[id]
    end

    def self.add user
      @@all_users[user.id] = user
      user
    end
  end

  class Site < Struct.new(:id, :title, :migration_map, keyword_init: true)
    @@sites ||= Hash.new
    def self.add site
      @@sites[site.id] = site
    end

    def self.find_by_domain domain
      case domain
      when "answers.ros.org"
        @@sites["ros"]
      when "answers.gazebosim.org"
        @@sites["gz"]
      end
    end
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
      data_path = File.expand_path(@config.data_path)
      @ros_db = Sequel.sqlite('data/ros_dump.db')
      @gz_db = Sequel.sqlite('data/gazebo_dump.db')
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
        Site.add(Site.new(id: id, title: title, migration_map: migration_map))
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
        #JSON.load_file(File.join(@data_path, "#{site.id}_unexported_se_dump.json"))["Questions"] +
        #JSON.load_file(File.join(@data_path, "#{site.id}_se_dump.json"))["Questions"]
        JSON.load_file(File.join(@data_path, "updated_dump.json"))["Questions"]
      )
      site_questions = site_questions.select do |json|
        site.migration_map.has_key? json["OriginalPostID"]
      end if @config.only_migrated

      site_questions = site_questions.select do |json|
        json["Answers"].size > 0
      end if @config.only_answered

      site_questions = site_questions.select do |json|
        json["Comments"].size > 0
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
