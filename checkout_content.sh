#!/bin/sh


if git status --porcelain 2>&1 | grep -qs .; then
	>&2 echo "Warning! Uncommitted changes and untracked files in content/ will be removed!"
	>&2 echo "         Set the NUKE_FROM_ORBIT environment variable if you want to proceed anyway."
	if test -z "${NUKE_FROM_ORBIT}"; then
		exit 5
	fi
fi

if test -z "$1"; then
	>&2 echo "No content argument. Specify `ros` or `gazebo`." 
	exit 1
fi

case "$1"
	ros)
		BRANCH=ros-content
		;;
	gazebo)
		BRANCH=gazebo-content
		;;
	*)
		>&2 echo "No content branch for $1. Specify `ros` or `gazebo`."

		exit 1
esac

git checkout .
git clean -fx content/question/ nanoc.yaml
git restore --source $BRANCH content/question/
git show $BRANCH:content_config.yml >> nanoc.yaml
