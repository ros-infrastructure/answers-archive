require "date"
require "sequel"


class PostsDataSource < Nanoc::DataSource
  identifier :questions

  def up
    @sites = Hash.new
    @sites[:ros] = Sequel.sqlite('data/ros_dump.db')
    @sites[:gz] = Sequel.sqlite('data/gazebosim_dump.db')
  end

  def nanoc_identifier post_id, site_id
    post = @sites[site_id][:posts].where(id: post_id).first
    if post[:parent_id]
      "#{nanoc_identifier(post[:parent_id], site_id)}/#{post[:post_type]}/#{post_id}"
    else
      "/#{site_id}/#{post[:post_type]}/#{post_id}"
    end
  end



  def items
    return @items if defined?(@items)

    @items = Array.new
    @sites.each do |site_id, db|
      db[:posts].order(:id).each do |post|
        @items << new_item(
          post[:body],
          {
            site: "ros",
            post_id: post[:id],
            title: post[:title],
            tags: post[:tags]&.split(",") || [],
            creation_date: DateTime.parse(post[:creation_date]),
            upvote_count: post[:upvote_count],
            user_id: post[:user_id],
          },
          Nanoc::Identifier.new("#{nanoc_identifier(post[:id], site_id)}.md")
      )
      end
    end
    @items
  end
end
