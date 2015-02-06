#!/bin/bash

readonly PROJECT="PEAppTransaction-Logger"
readonly VERSION="$1"
readonly TAG_LABEL=${PROJECT}-v${VERSION}

git tag -f -a $TAG_LABEL -m 'version $version'
git push -f --tags
