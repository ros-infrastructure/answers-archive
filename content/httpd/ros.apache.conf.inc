<% @items.find_all('/question/*.md').each do |post| %>
Redirect 301 "/question/<%= post[:original_post_id] %>(/|$)" "<%= post[:migrated_url] %>"
<% end %>
