location /question/ {
	<% @items.find_all('/questions/*.md').each do |post| %>
	location *~ /<%= post[:original_post_id] %>(/|$) {
		return 301 <%= post[:migrated_url] %>
	}
	<% end %>
}
