#!/bin/bash

download_file() {
  local url=$1
  local output_file=$2

  wget -O "${output_file}" "${url}" || { echo "Error while downloading ${output_file}"; exit 1; }
}

update_model_paths() {
  local branch=$1
  local build_config

  build_config=$(jq -r ".${branch}.build_config" < .wago_tools.json)
  if [ -z "${build_config}" ] || [ "${build_config}" == "null" ]; then
    echo "${branch} build_config not found in .wago_tools.json"
    return
  fi

  local last_build_file=".last_${branch}_build"
  if [ -f "${last_build_file}" ] && [[ ${build_config} == $(cat "${last_build_file}") ]]; then
    echo "${branch} build_config has not changed"
    return
  fi

  echo "New ${branch} build detected"
  local csv_file="${branch}.csv"
  download_file "https://wago.tools/api/files?branch=${branch}&search=.m2&format=csv" "${csv_file}"
  echo "${build_config}" > "${last_build_file}"
  lua csv_to_lua.lua "${branch}" || { echo "Error while creating ${branch}.lua"; exit 1; }
}

download_file "https://wago.tools/api/builds/latest" ".wago_tools.json"

branches=("wow_classic_titan" "wow_classic" "wow_classic_era")

for branch in "${branches[@]}"
do
  update_model_paths "$branch"
done

mv ModelPaths*.lua ../../WeakAurasModelPaths/
