# Redirect posts migrated to StackExchange to their migrated url.
<% @items.find_all('/question/*.md').select{|post| post[:migrated_url]}.each do |post| %>
RedirectMatch 301 "/question/<%= post[:original_post_id] %>(/|$)" "<%= post[:migrated_url] %>"
<% end %>

RewriteEngine on
# Support question urls with title slugs
RewriteCond "%{REQUEST_URI}" "!question/\d+/index\.html$"
RewriteRule "question/(\d+)/.+" "/question/$1/" [R=301,L]

# Support user urls with username slugs
RewriteCond "%{REQUEST_URI}" "!users/\d+/index\.html$"
RewriteRule "users/(\d+)/.+" "/users/$1/" [R=301,L]
