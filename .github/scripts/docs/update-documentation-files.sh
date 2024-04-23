#!/bin/bash

lua-language-server --doc="../../.." --doc_out_path="."

# jq '[.[] | select(.name | index("WeakAuras") != -1)]' doc.json > output.json

node parser.js > ../../../WeakAurasOptions/WeakAurasAPI.lua
