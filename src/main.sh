#!/usr/bin/bash

DEPS="curl jq git 7z date"
for DEP in $DEPS; do
    which $DEP
    if [[ $? != 0 ]]; then
        echo "Missing dependency $DEP"
        exit 1
    fi
done

OWNER=$1
REPO=$2
REPO_PATH=$3
API_TOKEN=$4

if [ -z $OWNER ]; then
    echo "Missing positional arg #1: Owner"
    exit 1
fi

if [ -z $REPO ]; then
    echo "Missing positional arg #2: Repo"
    exit 1
fi

if [ -z $REPO_PATH ]; then
    echo "Missing positional arg #3: Repo Path"
    exit 1
fi

if [ -z $API_TOKEN ]; then
    echo "Missing positional arg #4: API Token"
    exit 1
fi

GH_API="https://api.github.com"
GH_REPO="$GH_API/repos/$OWNER/$REPO"
GH_TAGS="$GH_REPO/releases/latest"
AUTH="Authorization: token $API_TOKEN"

# test the api token
curl -o /dev/null -sH "$AUTH" $GH_REPO
if [[ $? != 0 ]]; then
    echo "Invalid API Token, repo, or network issue"
    exit 1
fi

cd $REPO_PATH
if [[ $? != 0 ]]; then
    echo "Failed to enter directory $REPO_PATH"
    exit 1
fi

git pull
if [[ $? != 0 ]]; then
    echo "Failed to pull repository."
    exit 1
fi

LAST_COMMIT=`git log -1 --format="%at" | xargs -I{} date +%s -d @{}`
LAST_RELEASE=`curl -s https://api.github.com/repos/$OWNER/$REPO/releases/latest | jq -r ".created_at"`
LAST_RELEASE=`date +%s --date="$LAST_RELEASE"`

if [[ $LAST_COMMIT == $LAST_RELEASE ]]; then
    echo "No Release Needed"
    exit 0
fi

rm -rf bin build
./compile.sh clean

FILENAME="ImageDecompiler_Win64_Release_$LAST_COMMIT.zip"
7z a -tzip -mx9 "$FILENAME" ./bin/Release

TAG_NAME="$LAST_COMMIT"
CUR_TIME=`date`
RELEASE_NAME="Release on $CUR_TIME"
RELEASE_DESC="Build created on $CUR_TIME for Win64 based on latest commit on master branch."

RELEASE_JSON="{
    \"tag_name\": \"$TAG_NAME\",
    \"target_commitish\": \"master\",
    \"name\": \"$RELEASE_NAME\",
    \"body\": \"$RELEASE_DESC\",
    \"draft\": false,
    \"prerelease\": false
}"

# create release
curl -v -i -X POST -H "Content-Type:application/json" -H "Authorization: token $API_TOKEN" "https://api.github.com/repos/$OWNER/$REPO/releases" -d "$RELEASE_JSON"

# get release ID
response=$(curl -sH "$AUTH" $GH_TAGS)
ASSET_ID=`echo $response | jq -r ".id"`

# upload release asset
GH_ASSET="https://uploads.github.com/repos/$OWNER/$REPO/releases/$ASSET_ID/assets?name=$FILENAME" 
curl -H "Authorization: token $API_TOKEN" -H "Content-Type: application/zip" --data-binary @"$FILENAME" $GH_ASSET

rm $FILENAME

echo ""
echo ""
echo "Release Upload Done!"
echo ""