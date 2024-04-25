#!/bin/bash

lua-language-server --doc="." --doc_out_path=".github/scripts/docs"

# jq '[.[] | select(.name | index("WeakAuras") != -1)]' doc.json > output.json

node .github/scripts/docs/parser.js > WeakAurasOptions/WeakAurasAPI.lua
