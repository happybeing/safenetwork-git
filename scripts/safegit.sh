#!/bin/bash
set +x  # Don't echo output
set -e  # Exit on error

# TODO:
# [ ] add 'safegit fork <sub-name>.<public-name> [<your-sub-name>.]<your-public-name>' 
#     which creates a fork of <sub-name>.<public-name> at <sub-name>.<your-public-name>, as 
#     follows:
#        safe files get -r <sub-name>.<public-name> <your-public-name>
#        cd <your-public-name>
#        safegit.sh create <sub-name>.<your-public-name> # which sets up remote 'safegit'
# [ ] obtain <repo-name> from `git remote -v` instead of the command line so that
#     safegit push doesn't need a parameter.

usage() {
  echo ""
  echo "Usage: safegit.sh [create|push] [repo-name]"
  echo ""
  echo "Create a safegit headless repo, or push to your remote on SAFE Network"
  echo ""
  echo "<repo-name> must be an existing SAFE Network subname followed by '.',"
  echo "followed by a public name (e.g. 'dweb-blog.dgit')."
  echo ""
  echo "NOTES:"
  echo " - assumes you have the SAFE Command Line Interface installed"
  echo " - set SAFEGIT_DIR to override the default (HEADLESS_DIR below)"
  echo " - you must create the public names and subnames (services) of"
  echo "   <repo-name> before using safegit (see SAFE CLI User Guide)."
  echo " - tutorial available at:"
  echo "     http://dweb.happybeing.com/blog/post/002-safegit-decentralised-git-on-safe-network/"
  echo ""
  echo "Summary:"
  echo "   safegit.sh create <repo-name>"
  echo "if executed in a git repository will attempt to initialise a headless"
  echo "repository <repo-name> in $HEADLESS_DIR (or in $SAFEGIT_DIR if set)"
  echo "and set it as a remote: 'safegit'."
  echo ""
  echo "   safegit.sh push <repo-name>"
  echo "if executed in a git repository will push master to 'safegit',"
  echo "and then attempt to synchronise the files in the safegit headless"
  echo "repository with the corresponding location on SAFE Network. Then"
  echo "others can access the published remote directory using:"
  echo "   safe files get safe://<repo-name>"
  echo ""
  echo "You can push any branch with 'git push safegit <any-branch>' and then"
  echo "a subsequent 'safegit.sh push <repo-name>' will include that branch."
  echo ""
  echo "EXAMPLE"
  echo ""
  echo "Step 1: Create a Repository Location on SAFE Network"
  echo ""
  echo "Say you have a repository ~/dweb-blog and wish to publish this on"
  echo "SAFE Network at safe://dweb-blog.dgit. First you must have created"
  echo "the locations on SAFE Network using 'safe nrs' as follows:"
  echo ""
  echo "First create an empty file container on the network"
  echo "   mkdir empty-directory"
  echo "   safe files put -r empty-directory"
  echo "   rmdir empty-directory"
  echo "   safe nrs create dweb-blog.dgit --link <safe-xor-url-from-files-put-command>?v=0"
  echo ""
  echo "Note: if you later add another repo with a different subname, such"
  echo "      as new-blog.dgit you would repeat the above commands but use"
  echo "      'safe nrs add' instead of safe nrs create', because you are"
  echo "      adding a subname rather than creating a new NRS name."
  echo ""
  echo "Continuing the example, you have now created the location for your"
  echo "blog on SAFE Network: safe://dweb-blog.dgit, but it is currently"
  echo "empty. Now you need to create a headless repository and publish"
  echo "it at safe://dweb-blog.dgit."
  echo ""
  echo "Step 2: Create a Headless Mirror Repository"
  echo ""
  echo "For example, with repo-name 'dweb-blog.dgit', and the default"
  echo "HEADLESS_DIR of ~/safegit, when you execute:"
  echo "   cd ~/dweb-blog"
  echo "   safegit.sh create dweb-blog.dgit"
  echo ""
  echo "it will create a new directory ~/safegit/dweb-blog.dgit containing"
  echo "a headless repository that mirrors your working repository. Now you"
  echo "can publish it to the location created in step 1."
  echo ""
  echo "Step 3: Publish your Repository to SAFE Network"
  echo ""
  echo "The repo-name 'dweb-blog.dgit' can be published to SAFE Network with:"
  echo "   cd ~/dweb-blog"
  echo "   safegit.sh push dweb-blog.dgit"
  echo ""
  echo "after which anyone can get a copy of the repo using:"
  echo "   safe files get safe://dweb-blog.dgit"

}

# Headless repos are stored in $HEADLESS_DIR, but you can
# override this by setting SAFEGIT_DIR in your environment
HEADLESS_DIR=~/safegit
if [ ! "$SAFEGIT_DIR" = "" ]; then HEADLESS_DIR=$SAFEGIT_DIR ; fi

LOCAL_REPO=$(pwd)
HEADLESS_REPO=$2
PARAM_REPO=$2
HEADLESS_PATH=$HEADLESS_DIR/$HEADLESS_REPO

SAFE_PATH="safe://$PARAM_REPO"
SAFE_SERVICE=${PARAM_REPO/\.*/}
SAFE_NAME=${PARAM_REPO/*\./}
if [ "$SAFE_SERVICE" = "" -o "$SAFE_NAME" = "" ]; then echo "Error: you must provide a valid repo-name (a subname followed by '.' followed by a public name)" && usage && exit 1; fi


cleanup() {
  cd $LOCAL_REPO
}
trap cleanup EXIT

if [ ! -e "$LOCAL_REPO/.git" ]; then echo "Error, not a git repository: $LOCAL_REPO" && usage && exit 1; fi

# Create
if [ $1 = 'create' ]; then
  mkdir -p $HEADLESS_DIR
  cd $HEADLESS_DIR
  if [ -e "$PARAM_REPO" ]; then echo "Error, directory exists: $HEADLESS_DIR/$PARAM_REPO" && usage && exit 1; fi
  git init --bare $HEADLESS_REPO
  cd $LOCAL_REPO
  git remote add safegit $HEADLESS_PATH
  exit 0
fi

# Sync
if [ $1 = 'push' ]; then
  read -p "If you are logged into SAFE Network ENTER to continue..."
  git push safegit
  echo "Syncing to $SAFE_PATH..."
  safe files sync -r -d -u $HEADLESS_PATH/ $SAFE_PATH
  exit 0
fi

set +x  # Don't echo output
usage
