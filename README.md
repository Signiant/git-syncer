# git-syncer
Stay in sync with a git repo

## Variables

- VERBOSE - enable more logging if set to 1
- FREQUENCY - How often to check for changes (in seconds). Default is 300 seconds (5 minutes).
- REPO_DIR - folder for the git repo (can be existing git repo folder, or empty, or non-existant)
- REPO_URL - URL to the git repo to monitor
- REPO_BRANCH - Branch to track. Default is master
- GIT_CRED - path to where to find .git-credentials file to use (defaults to /credentials/.git-credentials)
    - only required for private repos
    - be sure to mount folder with .git-credentials file to whatever path is specified here
- MARKER_FILE - path to file to touch if changes are detected in the git repo, if not provided - no marker file created


## Example Docker runs


This example mounts the local folder 'mylocaldir/repo' into the container at '/my/repo/path' for use as the REPO_DIR. A local .git-credentials file ('credentials-dir/.git-credentials') is mounted at '/credentials/.git-credentials'. The syncer will check the upstream repo (https://github.com/Signiant/git-syncer.git) every 10 minutes (600 seconds). No new marker file will be created if/when new changes are pulled down.


````
docker run -d   -e "FREQUENCY=600" \
        -e "VERBOSE=1" \
        -e "REPO_DIR=/my/repo/path \
        -e "REPO_URL=https://github.com/Signiant/git-syncer.git \
        -v credentials-dir:/credentials \
        -v mylocaldir/repo:/my/repo/path \
        signiant/git-syncer
````

This example mounts the local folder 'mylocaldir/repo' into the container at '/my/repo/path' for use as the REPO_DIR. A local git-credentials file ('credentials-dir/.git-credentials') is mounted at '/credentials/.git-credentials'. The syncer will check the upstream repo (https://github.com/Signiant/git-syncer.git) every 1 minute (60 seconds). A marker file will be created (at /path/to/marker/file/NEWCONTENT) if/when new changes are pulled down. Since '/path/to/marker/file/' is mounted to 'mylocaldir', a NEWCONTENT file will get created in that folder locally


````
docker run -d -e "FREQUENCY=60"          \
        -e "REPO_DIR=/my/repo/path \
        -e "REPO_URL=https://github.com/Signiant/git-syncer.git \
        -e "REPO_BRANCH=non-master-branch \
        -e "MARKER_FILE=/path/to/marker/file/NEWCONTENT"
        -v credentials-dir:/credentials \
        -v mylocaldir/repo:/my/repo/path \
        -v mylocaldir:/path/to/marker/file \
        signiant/git-syncer
````





