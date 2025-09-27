--[[
Written in 2019 by Allen Faure (emptyrivers) afaure6@gmail.com

To the extent possible under law, the author(s) have dedicated all copyright and related and neighboring rights to this software to the public domain worldwide.
This software is distributed without any warranty.
You should have received a copy of the CC0 Public Domain Dedication along with this software.
If not, see http://creativecommons.org/publicdomain/zero/1.0/.
]]

local Archivist = select(2, ...).Archivist

-- super simple data store that just holds data

local prototype = {
	id = "RawData",
	version = 1,
	Create = function(self, data)
		if type(data) ~= "table" then
			data = {}
		end
		return data, data
	end,
	Open = function(self, data) return data end,
	Commit = function(self, store) return store end,
	Close = function(self, store) return store end,
}

Archivist:RegisterStoreType(prototype)