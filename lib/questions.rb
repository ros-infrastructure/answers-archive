require "json"

class QuestionsDataSource < Nanoc::DataSource
  identifier :questions

  def up
    # TODO parameterize and add other site sources.
    @gz_answers = JSON.load(File.read('answers/final_gazebo_se_dump.json'))["Questions"]
  end

  def attributes_from_json json
    Hash[
      original_post_id: json['OriginalPostID'],
      title: json['Title'],
      owner_display_name: json['OwnerDisplayName'],
      creation_date: json['CreationDate'],
      upvote_count: json['UpvoteCount'],
      original_post_url: json['OriginalPostURL'],
      # TODO answers
    ]
  end

  def items
    @gz_answers.map do |question|
      attributes = attributes_from_json(question)
      attributes[:site] = 'Gazebo Answers'
      new_item(
        question['BodyMarkdown'],
        attributes,
        Nanoc::Identifier.new("/gz/question/#{question["OriginalPostID"]}.md")
      )
    end
  end
end
