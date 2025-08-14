#!/user/bin/env bash

set -e #exists script if there is an error

pushd ~/.nixos

git stash # stash local changes

git pull origin master # pull changes from repo

git stash pop # apply stashed changes and resolve merge conflicts

popd
