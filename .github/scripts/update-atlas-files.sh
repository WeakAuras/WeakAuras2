#!/bin/bash

for version in wow wow_classic wow_classic_beta wow_classic_era
do
  wget -O "UiTextureAtlas.csv" "https://wago.tools/db2/UiTextureAtlas/csv?branch=${version}"
  wget -O "UiTextureAtlasMember.csv" "https://wago.tools/db2/UiTextureAtlasMember/csv?branch=${version}"
  wget -O "UiTextureAtlasElement.csv" "https://wago.tools/db2/UiTextureAtlasElement/csv?branch=${version}"

  lua ./atlas_update.lua ${version}
done

mv Atlas_Retail.lua ../../WeakAuras/
mv Atlas_Wrath.lua ../../WeakAuras/
mv Atlas_Vanilla.lua ../../WeakAuras/
mv Atlas_Cata.lua ../../WeakAuras/
