<% @items.find_all('/question/*.md').select{|post| post[:migrated_url]}.each do |post| %>
RedirectMatch 301 "/question/<%= post[:original_post_id] %>(/|$)" "<%= post[:migrated_url] %>"

RedirectMatch 301 "/question/(\d+)/..+" "/question/$1"
RedirectMatch 301 "/users/(\d+)/.+" "/users/$1/"
<% end %>
