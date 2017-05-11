#!/bin/bash

if [ "$VERBOSE" ]; then
    echo "Verbose logging enabled"
    set -x
fi

if [ "$UMASK" ]; then
    echo "setting given UMASK - all files and folder created will use a umask value of $UMASK"
    umask $UMASK
fi

REPO_DIR=/repo-dir

if [ -z "$REPO_URL" ]; then
    echo "Must supply the URL for the repo by setting the REPO_URL environment variable"
    exit 1
else
    echo "Repo URL set to $REPO_URL"
fi

if [ -z "$GIT_CRED" ]; then
    GIT_CRED=/credentials/.git-credentials
    echo "GIT_CRED environment variable missing - assuming default of ${GIT_CRED}"
fi

if [ ! -e "$GIT_CRED" ]; then
    echo ".git-credentials file not found - if $REPO_URL is a public repo, this shouldn't be a problem"
    echo "but if not, you will need to mount .git-credentials at ${GIT_CRED}"
fi

if [ -z "$MARKER_FILE" ]; then
    echo "MARKER_FILE environment variable NOT set - will NOT create a marker file when changes detected"
else
    echo "MARKER_FILE set to $MARKER_FILE"
fi

# Set a default frequency of 300 seconds if not set in the env
if [ -z "$FREQUENCY" ]; then
    echo "FREQUENCY not set - defaulting to 300 seconds"
    FREQUENCY=300
else
    echo "Frequency set to $FREQUENCY second"
fi

# Set a default branch of master if not set in the env
if [ -z "$REPO_BRANCH" ]; then
    echo "REPO_BRANCH not set - defaulting to master"
    REPO_BRANCH=master
else
    echo "Repo BRANCH set to $REPO_BRANCH"
fi

SETUP=0
# Check to see if the repo dir exists and is a git repo
# This would only be the case if someone mounted a local folder into the container
# at /repo-dir
if [ -e "$REPO_DIR" ]; then
    # directory exists
    if [ -e "$REPO_DIR/.git" ]; then
        echo "Supplied Repo DIR already is a git repo - checking to make sure it matches supplied repo"
        cd $REPO_DIR
        existing_repo_url=$(git config --get remote.origin.url)
        if [ "$existing_repo_url" != "$REPO_URL" ]; then
            echo "Supplied Repo DIR is already a git repo, but repo URL doesn't match supplied repo URL - cannot continue"
            exit 1
        fi
        git checkout $REPO_BRANCH
    else
        # Directory doesn't contain .git - check if it's empty
        if [ "$(ls -A $REPO_DIR)" ]; then
            echo "Supplied Repo DIR exists, but is NOT empty and is NOT a git repo - cannot continue"
            exit 1
        fi
        cd $REPO_DIR
        git init .
        SETUP=1
    fi
else
    echo "Supplied Repo DIR does not exist - will create it and pull down latest for BRANCH $REPO_BRANCH from $REPO_URL"
    mkdir -p $REPO_DIR
    cd $REPO_DIR
    git init .
    SETUP=1
fi

# Set up git credentials
credential_helper=$(git config --get credential.helper)
if [ "$credential_helper" != "store --file=$GIT_CRED" ]; then
    echo "Modifying credential.helper to point to supplied .git-credentials file"
    git config credential.helper 'store --file='$GIT_CRED
fi

if [ "$SETUP" -eq 1 ]; then
    git config remote.origin.url $REPO_URL
    git config branch.master.remote origin
    git config remote.origin.fetch +refs/heads/*:refs/remotes/origin/*
    git config branch.master.merge refs/heads/$REPO_BRANCH
    git pull
fi

current_head=`git rev-parse HEAD`

# Loop forever, sleeping for our frequency
while true
do
    echo "Awoke to check for new commits in $REPO_URL on branch $REPO_BRANCH"
    git pull
    new_head=`git rev-parse HEAD`

    if [ "$current_head" != "$new_head" ]; then
        # Found a change
        echo "New commits pulled down:"
        git rev-list --format=%B --reverse --pretty $current_head..HEAD
        current_head=$new_head
        # If a MARKER_FILE has been configured - touch it
        if [ ! -z "$MARKER_FILE" ]; then
            mkdir -p `dirname $MARKER_FILE`
            touch ${MARKER_FILE}
        fi
    else
        echo "No changes"
    fi

    echo "Sleeping for $FREQUENCY seconds"
    sleep $FREQUENCY
    echo
done

exit 0
