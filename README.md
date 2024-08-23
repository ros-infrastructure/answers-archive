# ROS and Gazebo Answers archive

This static site generator is designed to build a static archive of questions and other metadata from the decomissioned [Askbot](https://askbot.com/)-hosted ROS Answers and Gazebo Answers Q&A forums.

It is built using [nanoc](https://nanoc.app) with questions exported as static markdown files.

Many questions from these sites were migrated to [Robotics StackExchange](https://robotics.stackexchange.com) but those that were not remain here.
This project will also generate the redirect configuration to redirect migrated questions to their new home on Robotics StackExchange.

## Local development

There is an [Earthly](https://earthly.dev) build configuration for running the build in containers.

#### Checking out site content

Content for ROS and Gazebo Answers are stored on separate content branches of this repository.
To populate content in your local worktree, use the `+checkout` target and specify `ros` or `gazebo` with the `CONTENT` build argument.

:warning:
The archive of ROS content is *large* and will take time to check out and build.
Building the ROS archive can take six to ten minutes depending on the size of your workstation.
:warning:

```
earthly +checkout --CONTENT=gazebo
```

#### Building the site

Once content is checked out you can build the site with the `+compile` target.
After compilation is complete the generated site will be saved to the `output` directory locally.

```
earthly +compile
```

#### Viewing the site

In order to test the full site configuration with redirect behavior and all, you can generate a container image configuring ASF httpd with the `+server` target.

```
earthly +server --CONTENT=gazebo
```

You can then run the created container image with your preferred container client: (`docker`, `podman`, etc)
```
docker run -p 80:80 gazebo-answers-httpd
```

It will then be visible at <http://localhost>


Alternatively, you can view the site with a local web server of your choice such as python's build in http server

```
pushd output; python3 -m http.server; popd
```

### Without using Earthly

For local development without using Earthly you'll need:
* [Ruby](https://ruby-lang.org) >= 3.2
* [Bundler](https://bundler.io)

#### Checking out site content

Use the `checkout_content.sh` script to populate content.

```
./checkout_content.sh gazebo
```

#### Building the site

```
bundle install
bundle exec nanoc
```

#### Viewing the site

```
bundle exec nanoc view
```

The site will be available at `http://localhost:3000`
