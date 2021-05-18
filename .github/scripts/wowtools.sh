#!/bin/bash

wget -O ".wowtools.json" "https://wow.tools/api.php?type=currentbc"

if [[ $? -ne 0 ]]; then
    echo "error while downloading .wowtools.json"
else
    for version in wow wow_classic wow_classic_era
    do
        build=$(cat .wowtools.json | jq -r ".${version}")
        if [ -z "${build}" ]; then
            "${version} build not found in .wowtools.json"
        else
            lastbuildfile=".last${version}build"
            if [[ ${build} == $(cat ${lastbuildfile}) ]]; then
                echo "${version} build has not changed"
            else
                echo "new ${version} build detected"
                csvfile="${version}_list.csv"
                wget -O ${csvfile} "https://wow.tools/casc/listfile/download/csv/build?buildConfig=${build}&typeFilter=m2"
                if [ $? -ne 0 ]; then
                    echo "error while downloading ${csvfile}"
                else
                    echo "${build}" > ${lastbuildfile}
                    lua ./csv_to_lua.lua ${version}
                    if [ $? -ne 0 ]; then
                      echo "error while creating ${version} lua file"
                    else
                      mv ModelPaths*.lua ../../WeakAurasModelPaths/
                    fi
                fi
            fi
        fi
    done
fi
