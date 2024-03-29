require "json"
require "yaml"

class QuestionsDataSource < Nanoc::DataSource
  identifier :questions

  def up
    config = QuestionData::Config.new(
      data_path: File.expand_path("./data")
    )
    if ENV['XTEST_ANSWERS_DEBUG']
      yaml = YAML.load_file("nanoc.yaml")["data_sources"].select{|ds| ds["type"] == "questions"}.first["xtest"]
      config.max_per_site = yaml["max_per_site"]
      config.only_commented = yaml["only_commented"]
      config.only_answered = yaml["only_answered"]
      config.only_migrated = yaml["only_migrated"]
    end

    data_reader = QuestionData::DataReader.new(config)
    @questions = data_reader.questions
  end

  def items
    return @items if defined?(@items)

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
