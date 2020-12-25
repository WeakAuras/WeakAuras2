#!/bin/bash

wget -O ".wowtools.json" "https://wow.tools/api.php?type=currentbc"

if [[ $? -ne 0 ]]; then
    echo "error while downloading .wowtools.json"
else
    wowbuild=`cat .wowtools.json | jq -r '.wow'`
    classicwowbuild=`cat .wowtools.json | jq -r '.wow_classic'`

    if [ -z "${wowbuild}" ]; then
        echo "\$wowbuild build not found"
    else
        if [[ ${wowbuild} == `cat .lastwowbuild` ]]; then
            echo "wow build has not changed"
        else
            echo "new wow build detected"
            wget -O "retail_list.csv" "https://wow.tools/casc/listfile/download/csv/build?buildConfig=${wowbuild}&typeFilter=m2"
            if [ $? -ne 0 ]; then
                echo "error while downloading retail_list.csv"
            else
                echo ${wowbuild} > .lastwowbuild
                lua ./csv_to_lua.lua retail
                if [ $? -ne 0 ]; then
                  echo "error while creating classic lua file"
                else
                  mv ModelPaths.lua ../../WeakAurasModelPaths/
                fi
            fi
        fi
    fi

    if [ -z "${classicwowbuild}" ]; then
        echo "\$classicwow build not found"
    else
        if [[ ${classicwowbuild} == `cat .lastclassicwowbuild` ]]; then
            echo "classicwow build has not changed"
        else
            echo "new classicwow build detected"
            wget -O "classic_list.csv" "https://wow.tools/casc/listfile/download/csv/build?buildConfig=${classicwowbuild}&typeFilter=m2"
            if [ $? -ne 0 ]; then
                echo "error while downloading classic_list.csv"
            else
                echo ${classicwowbuild} > .lastclassicwowbuild
                lua ./csv_to_lua.lua classic
                if [ $? -ne 0 ]; then
                  echo "error while creating classic lua file"
                else
                  mv ModelPathsClassic.lua ../../WeakAurasModelPaths/
                fi
            fi
        fi
    fi
fi
