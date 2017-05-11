# git-syncer
Stay in sync with a git repo

## Variables

- VERBOSE - enable more logging if set to 1
- FREQUENCY - How often to check for changes (in seconds). Default is 300 seconds (5 minutes).
- REPO_URL - URL to the git repo to monitor
- REPO_BRANCH - Branch to track. Default is master
- GIT_CRED - path to where to find .git-credentials file to use (defaults to /credentials/.git-credentials)
    - only required for private repos
    - be sure to mount folder with .git-credentials file to whatever path is specified here
- MARKER_FILE - path to file to touch if changes are detected in the git repo, if not provided - no marker file created


## Example Docker runs


This example mounts the local folder 'mylocaldir/repo' into the container at '/repo-dir' for use as the Repo Folder.
A .git-credentials file can be found in the local 'credentials-dir', so 'credentials-dir' is mounted at '/credentials'
inside the container. The syncer will check the upstream repo (https://github.com/Signiant/git-syncer.git) every 10 
minutes (600 seconds). No new marker file will be created if/when new changes are pulled down.


````
docker run -d   -e "FREQUENCY=600" \
 -e "VERBOSE=1" \
 -e "REPO_URL=https://github.com/Signiant/git-syncer.git \
 -v credentials-dir:/credentials \
 -v mylocaldir/repo:/repo-dir \
 signiant/git-syncer
````

This example mounts the local folder 'mylocaldir/repo' into the container at '/repo-dir' for use as the Repo Folder.
No credentials file is mounted, because this is a public repo that doesn't need credentials. 
The syncer will check the upstream repo (https://github.com/Signiant/git-syncer.git) every minute
(60 seconds). A marker file WILL be created (at /monitor/NEWCONTENT) if/when new changes are pulled down.
Since '/monitor' is mounted to 'mylocaldir', a NEWCONTENT file will get created in that folder locally.


````
docker run -d -e "FREQUENCY=60" \
        -e "REPO_URL=https://github.com/Signiant/git-syncer.git \
        -e "MARKER_FILE=/monitor/NEWCONTENT"
        -v mylocaldir/repo:/repo-dir \
        -v mylocaldir:/monitor \
        signiant/git-syncer
````


This example combines a docker container created with the signiant/aws-parameter-syncer docker image, to keep the 
.git-credentials file in sync (in case there is a rotation policy in place for the password for example). The 
'/credentials' volume is exposed in the aws-parameter-syncer image, so let's assume there is already a docker container 
running with a name of 'credentialsSyncer' that is using that image, and that it syncs a parameter to a .git-credentials 
file in /credentials. We simply need to use the --volumes-from directive to get the /credentials volume shared into this 
container.  In this case, the Repo Folder (/repo-dir) is not mounted locally. The syncer will check the upstream repo 
(https://github.com/Signiant/git-syncer.git) every minute (60 seconds) for new commits to the 'non-master-branch'. A 
marker file WILL be created (at /monitor/NEWCONTENT) if/when new changes are pulled down. Since '/monitor' is mounted 
to 'mylocaldir', a NEWCONTENT file will get created in that folder locally.


````
docker run -d -e "FREQUENCY=60" \
        -e "REPO_URL=https://github.com/Signiant/git-syncer.git \
        -e "REPO_BRANCH=non-master-branch \
        -e "MARKER_FILE=/monitor/NEWCONTENT"
        --volumes-from credentialsSyncer
        -v mylocaldir:/monitor \
        signiant/git-syncer
````
