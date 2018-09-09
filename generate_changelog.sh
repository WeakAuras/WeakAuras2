#!/bin/bash

version=$( git describe --tags --always )
tag=$( git describe --tags --always --abbrev=0 )

if [ "$version" = "$tag" ]; then # on a tag
  current="$tag"
  previous=$( git describe --tags --abbrev=0 HEAD~ )
else
  current=$( git log -1 --format="%H" )
  previous="$tag"
fi

date=$( git log -1 --date=short --format="%ad" )
url=$( git remote get-url origin | sed -e 's/^git@\(.*\):/https:\/\/\1\//' -e 's/\.git$//' )
#title='# '${url##*/}
title="# WeakAuras 2"

echo -ne "# [${version}](${url}/tree/${current}) ($date)\n\n[Full Changelog](${url}/compare/${previous}...${current})\n\n" > "CHANGELOG.md"
if [ "$version" = "$tag" ]; then # on a tag
  highlights=$( git cat-file -p $tag | sed -e '1,5d' )
  echo -ne "## Highlights\n\n ${highlights} \n\n## Commits\n\n" >> "CHANGELOG.md"
fi
git shortlog --no-merges --reverse "$previous..$current" | sed -e  '/^\w/G' -e 's/^      /- /' >> "CHANGELOG.md"
#git log --pretty=format:"###%s" "$previous..$current" | sed -e 's/^/    /g' -e 's/^ *$//g' -e 's/^    ###/- /g' -e 's/$/  /' >> "CHANGELOG.md"
#echo >> "CHANGELOG.md"
