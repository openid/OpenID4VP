#!/bin/bash

# build the OID4VP spec and copy it into publication repo
#
# assumes you've done:
# git checkout git@github.com:openid/publication.git
# at the same level as OpenID4VP repo is checked out at, and that the publication repo
# is up to date / has no other changes / etc
#
# after running this script, run commands in that repo like:
# git checkout -b propose/oid4vp-30
# git add digital-credentials-protocols/openid*
# git commit -a -m 'Add OID4VP draft 30'
# git push -u origin HEAD
# then open a PR
#
# please also add a tag on the OpenID4VP repo,e.g. : git tag draft-30 && git push --tags

set -e

SPEC=openid-4-verifiable-presentations-1_0.md

# exit if uncommitted changes
# commands suggested by https://stackoverflow.com/questions/3878624/how-do-i-programmatically-determine-if-there-are-uncommitted-changes
git update-index --refresh || (echo "Aborted: Uncommitted changes found" && exit 1)
git diff-index --quiet HEAD -- || (echo "Aborted: Uncommitted changes found" && exit 1)

# get current draft number from this line in spec:
# value = "openid-4-verifiable-credential-issuance-1_0-14"
VERSION=`perl -ne 'print $1 and last if /^value = ".*-([0-9]+)"/' $SPEC`
if [ -z "$VERSION" ]; then
  echo "Unable to find spec version"
  exit 1
fi

echo "Spec version is '$VERSION'"

# change:
# title = "OpenID for Verifiable Credential Issuance - Editor's draft"
# to
# title = "OpenID for Verifiable Credential Issuance - draft 14"

perl -pi -e "s/^(title = \".* -) Editor.s draft\"/\$1 draft $VERSION\"/" $SPEC

# build spec
BASENAME=`basename $SPEC .md`
SPECHTML=${BASENAME}-${VERSION}.html
SPECXML=${BASENAME}-${VERSION}.xml
SPECZIP=${BASENAME}-${VERSION}.zip
SPECWITHVERSION=${BASENAME}-${VERSION}.md

rm -f $SPECHTML $SPECXML $SPECZIP $SPECHTMLWITHOUTVERSION $SPECXMLWITHOUTVERSION $SPECZIPWITHOUTVERSION

docker run -v `pwd`:/data danielfett/markdown2rfc $SPEC
if [ ! -e $SPECHTML ]; then
  echo "$SPECHTML not found after building spec"
  exit 1
fi
if [ ! -e $SPECXML ]; then
  echo "$SPECXML not found after building spec"
  exit 1
fi

# create numbered version of spec
cp $SPEC $SPECWITHVERSION

# zip source code
rm -f $SPECZIP
zip -r $SPECZIP $SPEC $SPECHTML $SPECXML examples/
echo "Created $SPECZIP"

cp $SPECWITHVERSION $SPECHTML $SPECZIP ../publication/digital-credentials-protocols/

echo "Finished. Now commit the files in the publication repo & open a PR there."
