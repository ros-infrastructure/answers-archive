# ROS and Gazebo Answers archive

This static site generator is designed to build a static archive of questions and other metadata from the decomissioned [Askbot](https://askbot.com/)-hosted ROS Answers and Gazebo Answers Q&A forums.

It is built using [nanoc](https://nanoc.app) with custom data sources to read JSON-formatted exports of the Askbot database and render questions as static files.

Many questions from these sites were migrated to [Robotics StackExchange](https://robotics.stackexchange.com) but those that were not remain here.
This project will also generate the redirect configuration to redirect migrated questions to their new home on Robotics StackExchange.

## Local development setup

Until a final database export has been included in the repository, you'll need to get the hard-coded json export archive from the shared drive and place it in the `answers/` directory.

Requirements
* [Ruby](https://ruby-lang.org) >= 3.0
* [Bundler](https://bundler.io)

#### Setup and build:

```
bundle install
bundle exec nanoc
```

#### Local preview at `http://localhost:3000`:

```
bundle exec nanoc view
```
