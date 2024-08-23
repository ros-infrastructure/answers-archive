<% @items.find_all('/question/*.md').select{|post| post[:migrated_url]}.each do |post| %>
RedirectMatch 301 "/question/<%= post[:original_post_id] %>(/|$)" "<%= post[:migrated_url] %>"

<% end %>

# These get foiled by index biz.
# I may have to resort to mod_rewrite.
#RedirectMatch 301 "/question/(\d+)/(?!index\.html)..+" "/question/$1/"
#RedirectMatch 301 "/users/(\d+)/.+" "/users/$1/"

