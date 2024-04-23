#!/bin/bash

luals="C:\Users\buds\.vscode\extensions\sumneko.lua-3.8.0-win32-x64\server\bin\lua-language-server.exe"

${luals} --doc="../../.." --logpath="."

node parser.js > ../../../WeakAurasOptions/WeakAurasAPI.lua
