location /question/ {
	<% migrated_ros_posts.each do |post| %>
	location *~ /<%= post[:original_post_id] %>(/|$) {
		return 301 <%= post[:migrated_url] %>
	}
	<% end %>
}
