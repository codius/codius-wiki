#!/bin/sh
# ideas used from https://gist.github.com/motemen/8595451

# Based on https://github.com/eldarlabs/ghpages-deploy-script/blob/master/scripts/deploy-ghpages.sh
# Used with their MIT license https://github.com/eldarlabs/ghpages-deploy-script/blob/master/LICENSE
# abort the script if there is a non-zero error
set -e

# show where we are on the machine
pwd
ls
# make a directory to put the gp-pages branch
mkdir ../codius-wiki-branch
cd ../codius-wiki-branch || exit
# now lets setup a new repo so we can update the gh-pages branch
git config --global user.email "$GH_EMAIL" > /dev/null 2>&1
git config --global user.name "$GH_NAME" > /dev/null 2>&1
git init

# switch into the the codius-wiki branch
if git rev-parse --verify origin/codius-wiki > /dev/null 2>&1
then
    git checkout codius-wiki
    # delete any old site as we are going to replace it
    # Note: this explodes if there aren't any, so moving it here for now
    git rm -rf .
else
    git checkout --orphan codius-wiki
fi

# copy over or recompile the new site
pwd
ls
cp -a "../project/." .
git remote remove origin
echo "remote removed"
git remote add codiusd "git@github.com:codius/codiusd.wiki.git"
git remote add codius "git@github.com:codius/codius.wiki.git"
git remote add codiuswiki "git@github.com:codius/codius-wiki.wiki.git"
echo "added new remote"
# stage any changes and new files
git add -A
# now commit, ignoring branch gh-pages doesn't seem to work, so trying skip
git commit --allow-empty -m "Deploy to GitHub pages [ci skip]"
# and push, but send any output to /dev/null to hide anything sensitive
git push --quiet codiusd master
git push --quiet codius master
git push --quiet codiuswiki master
# go back to where we started and remove the gh-pages git repo we made and used
# for deployment
cd ..
rm -rf codius-wiki-branch

echo "Finished Deployment!"
