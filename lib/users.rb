require "sequel"

class UsersDataSource < Nanoc::DataSource
  identifier :users

  def up
    @rosdb = Sequel.sqlite('data/ros_dump.db')
    @gzdb = Sequel.sqlite('data/gazebosim_dump.db')
  end

  def items
    return @items if defined?(@items)

    @items = Array.new
    @rosdb[:users].each do |user|
      @items << new_item(
        '',
        {
          name: user[:name],
          karma: user[:karma],
        },
        Nanoc::Identifier.new("/ros/user/#{user[:id]}.md")
      )
    end
    @gzdb[:users].each do |user|
      @items << new_item(
        '',
        {
          name: user[:name],
          karma: user[:karma],
        },
        Nanoc::Identifier.new("/gz/user/#{user[:id]}.md")
      )
    end
    @items
  end
end
