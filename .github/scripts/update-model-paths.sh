#!/bin/bash

update_model_paths() {
  branch=$1

  build_config=$(jq -r ".${branch}.build_config" < .wago_tools.json)
  if [ -z "${build_config}" ] || [ "${build_config}" == "null" ]; then
    echo "${branch} build_config not found in .wago_tools.json"
  else
    lastbuildfile=".last_${branch}_build"
    if [ -f "${lastbuildfile}" ] && [[ ${build_config} == $(cat "${lastbuildfile}") ]]; then
      echo "${branch} build_config has not changed"
    else
      echo "New ${branch} build detected"
      csvfile="${branch}.csv"
      wget -O "${csvfile}" "https://wago.tools/api/files?branch=${branch}&search=.m2&format=csv" || { echo "Error while downloading ${csvfile}"; exit 1; }
      echo "${build_config}" > "${lastbuildfile}"
      lua csv_to_lua.lua "${branch}" || { echo "Error while creating ${branch}.lua"; exit 1; }
    fi
  fi
}

wget -O ".wago_tools.json" "https://wago.tools/api/builds/latest" || { echo "Error while downloading .wago_tools.json"; exit 1; }

branches=("wow" "wow_classic" "wow_classic_beta" "wow_classic_era")

for branch in "${branches[@]}"
do
  update_model_paths "$branch"
done

mv ModelPaths*.lua ../../WeakAurasModelPaths/
