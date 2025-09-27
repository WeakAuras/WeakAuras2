--[[
Archivist - Data management service for WoW Addons
Written in 2019 by Allen Faure (emptyrivers) afaure6@gmail.com

To the extent possible under law, the author(s) have dedicated all copyright and related and neighboring rights to this software to the public domain worldwide.
This software is distributed without any warranty.
You should have received a copy of the CC0 Public Domain Dedication along with this software.
If not, see http://creativecommons.org/publicdomain/zero/1.0/.
]]

local embedder, namespace = ...
local addonName, Archivist = "Archivist", {}
-- Our only library!
local LibDeflate = LibStub("LibDeflate")

do -- boilerplate & static values
	Archivist.buildDate = "@build-time@"
	Archivist.version = "v1.0.8"
	--[==[@debug@
		Archivist.debug = true
	--@end-debug@]==]

	Archivist.prototypes = {}
	Archivist.storeMap = {}
	Archivist.activeStores = {}
	namespace.Archivist = Archivist
	local unloader = CreateFrame("FRAME")
	unloader:RegisterEvent("PLAYER_LOGOUT")
	unloader:SetScript("OnEvent", function()
		Archivist:DeInitialize()
	end)
	if embedder == "Archivist" then
		-- Archivist is installed as a standalone addon.
		-- The Archive is in the default location, ACHV_DB
		_G.Archivist = Archivist
		local loader = CreateFrame("frame")
		loader:RegisterEvent("ADDON_LOADED")
		loader:SetScript("OnEvent", function(self, _, addon)
			if addon == addonName then
				if type(ACHV_DB) ~= "table" then
					ACHV_DB = {}
				end
				Archivist:Initialize(ACHV_DB)
				self:UnregisterEvent("ADDON_LOADED")
			end
		end)
	end
end

function Archivist:Assert(valid, pattern, ...)
	if not valid then
		if pattern then
		error(pattern:format(...), 2)
		else
		error("Archivist encountered an unknown error.", 2)
		end
	end
end

function Archivist:Warn(valid, pattern, ...) -- Like assert, but doesn't interrupt execution
	if not valid and self.debug then
		if pattern then
			print(pattern:format(...), 2)
		else
			print("Archivist encountered an unknown warning.")
		end
		return true
	end
end

function Archivist:IsInitialized()
	return self.initialized
end

-- Give Archivist its archive to play with. Called automatically, unless Archivist has been embedded.
function Archivist:Initialize(sv)
	do -- arg validation
		self:Assert(not self:IsInitialized(), "Archivist has already been initialized.")
		self:Assert(type(sv) == "table", "Attempt to initialize Archivist SavedVariables with a %q instead of a table.", type(sv))
	end

	self.sv = sv
	self.initialized = true
	for id, prototype in pairs(self.prototypes) do
		self.sv[id] = self.sv[id] or {}
		if prototype.Init then
			prototype:Init()
		end
	end
end

-- Shut Archivist down
function Archivist:DeInitialize()
	if self:IsInitialized() then
		self.initialized = false
		self:CloseAllStores()
		self.sv = nil
	end
end

-- register a store type with Archivist
-- prototype fields:
--  id - unique identifier. Preferably also a descriptive name, like "simple" or "snapshot".
--  version - positive integer. Used for version control, in case any data migrations are needed. Registration will fail if the prototype is outdated.
--  Init - function (optional). If provided, executes exactly once per session, before any other methods are called.
--  Create - function (required). Create a brand new active store object.
--  Update - function (optional). Massage archived data into a format that Open can accept. Useful for data migrations.
--  Open - function (requried). Create from the provided data an active store object. Prototype may assume ownership of the provided data however it wishes.
--  Commit - function (required). Return an image of the data that should be archived.
--  Close - function (required). Release ownership of active store object. Optionally, return image of data to write into archive.
--  Delete - function (optional). If provided, called when a store is deleted. Useful for cleaning up sub stores.
-- Please note that Create, Open, Update (if provided), Commit, and Close may be called at any time if Archivist deems it necessary.
-- Thus, these methods should ideally be as close to purely functional as is practical, to minimize friction.
function Archivist:RegisterStoreType(prototype)
	do -- prototype validation
		self:Assert(type(prototype) == "table", "Invalid argument #1 to RegisterStoreType: Expected table, got %q instead.", type(prototype))
		-- prototype is now guaranteed to be indexable
		self:Assert(type(prototype.id) == "string", "Invalid prototype field 'id': Expected string, got %q instead.", type(prototype.id))
		self:Assert(type(prototype.version) == "number", "Invalid prototype field 'version': Expected number, got %q instead.", type(prototype.version))
		if self:Warn(prototype.version > 0 and prototype.version == math.floor(prototype.version),
			"Prototype %q version expected to be a positive integer, but got %d instead.", prototype.id, prototype.version) then
			return
		end
		local oldPrototype = self.prototypes[prototype.id]
		self:Assert(not oldPrototype or prototype.version >= oldPrototype.version, "Store type %q already exists with a higher version", oldPrototype and oldPrototype.version)
		-- prototype is now guaranteed to be either new or an Update to existing prototype
		self:Assert(prototype.Init == nil or type(prototype.Init) == "function", "Invalid prototype field 'Init': Expected function, got %q instead.", type(prototype.Init))
		self:Assert(type(prototype.Create) == "function", "Invalid prototype field 'Create': Expected function, got %q instead.", type(prototype.Create))
		self:Assert(type(prototype.Open) == "function", "Invalid prototype field 'Open': Expected function, got %q instead.", type(prototype.Open))
		self:Assert(prototype.Update == nil or type(prototype.Update) == "function", "Invalid prototype field 'Update': Expected function, got %q instead.", type(prototype.Update))
		self:Assert(type(prototype.Commit) == "function", "Invalid prototype field 'Commit': Expected function, got %q instead.", type(prototype.Commit))
		self:Assert(type(prototype.Close) == "function", "Invalid prototype field 'Close': Expected function, got %q instead.", type(prototype.Close))
		self:Assert(prototype.Delete == nil or type(prototype.Delete) == "function", "Invalid prototype field 'Delete': Expected function, got %q instead.", type(prototype.Delete))
		-- prototype is now guaranteed to have Init, Create, Open, Update functions, and is thus well-formed.
	end

	local oldPrototype = self.prototypes[prototype.id] -- need in case of closing active stores
	self.prototypes[prototype.id] = {
		id = prototype.id,
		version = prototype.version,
		Init = prototype.Init,
		Create = prototype.Create,
		Update = prototype.Update,
		Open = prototype.Open,
		Commit = prototype.Commit,
		Close = prototype.Close,
		Delete = prototype.Delete
	}
	self.activeStores[prototype.id] = self.activeStores[prototype.id] or {}
	if self:IsInitialized() then
		self.sv[prototype.id] = self.sv[prototype.id] or {}
		if prototype.Init then
			prototype:Init()
		end
		-- if prototype was previously registered, and Archivist is initialized, then there may be open stores of the old prototype.
		-- Close them, Update if necessary, then re-Open them with the new prototype.
		if oldPrototype then
			for storeID, store in pairs(self.activeStores[prototype.id]) do
				local image = oldPrototype:Close(store)
				local saved = self.sv[prototype.id][storeID]
				local shouldReArchive = image ~= nil
				if image == nil then
					image = saved.data
				end
				if prototype.Update then
					local newImage = prototype:Update(image, saved.version)
					if newImage ~= nil then
						image = newImage
						shouldReArchive = true
					end
					saved.version = prototype.version
				end
				self.activeStores[prototype.id][storeID] = prototype:Open(image)
				if shouldReArchive then
					-- a meaningful change to saved data has occurred.
					saved.data = self:Archive(image)
				end
			end
		end
	end
end

do -- function Archive:GenerateID()
	-- adapted from https://gist.github.com/jrus/3197011
	local function randomHex()
		return ('%x'):format(math.random(0, 0xf))
	end

	function Archivist:GenerateID()
		local template ='xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx'
		return (template:gsub('x', randomHex))
	end
end

-- creates and opens a new store of the given store type and with the given id (if given)
-- store objects are lightly managed by Archivist. On PLAYER_LOGOUT, all open stores are Closed,
-- and the resultant data is compressed into the archive.
function Archivist:Create(storeType, id, ...)
	do -- arg validation
		self:Assert(type(storeType) == "string" and self.prototypes[storeType], "Store type must be registered before loading data.")
		self:Assert(id == nil or type(id) == "string" and not self.sv[storeType][id], "A store already exists with that id. Did you mean to call Archivist:Open?")
	end

	local store, image = self.prototypes[storeType]:Create(...)
	do -- ensure that store exists and is unique
		self:Assert(store ~= nil, "Failed to create a new store of type %q.", storeType)
		self:Assert(self.storeMap[store] == nil, "Store Type %q produced an store object already registered with Archivist instead of creating a new one.", storeType)
	end

	if id == nil then
		id = self:GenerateID()
	end

	self.activeStores[storeType][id] = store
	self.storeMap[store] = {
		id = id,
		prototype = self.prototypes[storeType],
		type = storeType
	}

	if image == nil then
		-- save initial image via Commit
		image = self.prototypes[storeType]:Commit(store)
	end
	self:Assert(image ~= nil, "Create Verb failed to generate initial image for archive.")
	self.sv[storeType][id] = {
		timestamp = time(),
		version = self.prototypes[storeType].version,
		data = self:Archive(image)
	}

	return store, id
end

-- clones archived data and/or active store object to newId
-- also provides an active store object of the cloned data if openStore is set
function Archivist:Clone(storeType, id, newId, openStore)
	do -- arg validation
		self:Assert(type(storeType) == "string" and self.prototypes[storeType], "Store type must be registered to clone a store.")
		self:Assert(type(id) == "string" and (self.sv[storeType][id] or self.activeStores[storeType][id]), "Unable to clone store: store not found.")
	end

	if type(newId) ~= "string" then
		newId = self:GenerateID()
	end

	self:Assert(not self.sv[storeType][newId], "Store with ID %q already exists. Choose a different ID.")
	if self.activeStores[storeType][id] then
		-- go ahead and commit active store
		self:Commit(storeType, id)
	end

	-- thankfully, strings are easy to copy
	self.sv[storeType][newId] = {
		version = self.prototypes[storeType].version,
		timestamp = time(),
		data = self.sv[storeType][id].data
	}
	if openStore then
		return self:Open(storeType, newId), newId
	else
		return nil, newId
	end
end

function Archivist:CloneStore(store, newId, openStore)
	self:Assert(self.storeMap[store], "Unrecognized store was provided.")
	local info = self.storeMap[store]
	return self:Clone(info.type, info.id, newId, openStore)
end

-- Closes store (if open), then deletes data from archive
-- Prototype is given opportunity to perform actions using image (usually, to delete other sub stores)
-- if store type is not registered, then force flag must be set in order to delete data,
-- to reduce the chance of accidents
function Archivist:Delete(storeType, id, force)
	do -- arg validation
		self:Warn(force or type(storeType == "string") and self.sv[storeType], "There are no stores to delete.")
		self:Assert(force or self.prototypes[storeType], "Store type should be registered before deleting a store. Call Delete again with arg #3 == true to override this.")
	end

	if id and storeType and self.sv[storeType] then
		if self.prototypes[storeType] and self.prototypes[storeType].Delete and self.sv[storeType][id] then
			local image = self.activeStores[storeType][id]
						 and self:Close(self.activeStores[storeType][id])
						 or self:DeArchive(self.sv[storeType][id].data)
			self.prototypes[storeType]:Delete(image)
		end
		self.sv[storeType][id] = nil
	end
end

function Archivist:DeleteStore(store)
	self:Assert(self.storeMap[store], "Unrecognized store was provided.")
	local info = self.storeMap[store]
	return self:Delete(info.type, info.id)
end

-- unpacks data in the archive into an active store object
-- if store is already active, then returns active store object
function Archivist:Open(storeType, id, ...)
	do -- arg validation
		self:Assert(type(storeType) == "string" and self.prototypes[storeType], "Store type must be registered before opening a store.")
		self:Assert(type(id) == "string" and (self.sv[storeType][id] or self.activeStores[storeType][id]), "Could not find a store with that ID. Did you mean to call Archivist:Create?")
	end

	local store = self.activeStores[storeType][id]
	if not store then
		local saved = self.sv[storeType][id]
		local data = self:DeArchive(saved.data)
		local prototype = self.prototypes[storeType]
		-- migrate data...
		if prototype.Update and prototype.version > saved.version then
			local newData = prototype:Update(data, saved.version)
			if newData ~= nil then
				saved.data = self:Archive(newData)
				saved.timestamp = time()
			end
			saved.version = prototype.version
		end
		-- create store object...
		store = prototype:Open(data, ...)
		-- cache it so that we can close it later..
		self.activeStores[storeType][id] = store
		self.storeMap[store] = {
			id = id,
			prototype = self.prototypes[storeType],
			type = storeType
		}
	end
	return store
end

-- DANGEROUS FUNCTION
-- Your data will be lost. All of it. No going back.
-- Don't say I didn't warn you
function Archivist:DeleteAll(storeType)
	if storeType then
		self.sv[storeType] = {}
		for id, store in pairs(self.activeStores[storeType]) do
			self.activeStores[storeType][id] = nil
			self.storeMap[store] = nil
		end
	else
		for id in pairs(self.prototypes) do
			self.sv[id] = {}
			self.activeStores[id] = {}
		end
		self.storeMap = {}
	end
end

-- deactivates store, with one last opportunity to commit data if the prototype chooses to do so
function Archivist:Close(storeType, id)
	do -- arg validation
		self:Assert(type(storeType) == "string" and self.prototypes[storeType], "Closing a store of an unregistered store type doesn't make sense.")
		self:Warn(type(id) == "string" and self.activeStores[storeType][id], "No store with that ID can be found.")
	end

	local store = self.activeStores[storeType][id]
	local saved = self.sv[storeType][id]
	if store then
		local image = self.prototypes[storeType]:Close(store)
		if image ~= nil then
			saved.data = self:Archive(image)
			saved.timestamp = time()
		end
		self.activeStores[storeType][id] = nil
		self.storeMap[store] = nil
	end
end

function Archivist:CloseStore(store)
	self:Assert(self.storeMap[store], "Unrecognized store was provided.")
	local info = self.storeMap[store]
	return self:Close(info.type, info.id)
end

function Archivist:CloseAllStores()
	for storeType, prototype in pairs(self.prototypes) do
		for id, store in pairs(self.activeStores[storeType]) do
			local image = prototype:Close(store)
			local saved = self.sv[storeType][id]
			self.activeStores[storeType] = nil
			if image then
				saved.data = self:Archive(image)
				saved.timestamp = time()
			end
		end
	end
end

-- archives an image of the store object
function Archivist:Commit(storeType, id)
	do -- arg validation
		self:Assert(type(storeType) == "string" and self.prototypes[storeType], "Committing a store of an unregistered store type doesn't make sense.")
		self:Assert(type(id) == "string" and self.activeStores[storeType][id], "No store with that ID can be found.")
	end

	local store = self.activeStores[storeType][id]
	local image = self.prototypes[storeType]:Commit(store)
	local saved = self.sv[storeType][id]
	if image ~= nil then
		saved.data = self:Archive(image)
		saved.timestamp = time()
	end
end

function Archivist:CommitStore(store)
	self:Assert(self.storeMap[store], "Unrecognized store was provided.")
	local info = self.storeMap[store]
	return self:Commit(info.type, info.id)
end

-- opens or creates a storeType, depending on what is appropriate
-- this is the main entry point for other addons who just want their saved data
function Archivist:Load(storeType, id)
	do -- arg validation
		self:Assert(type(storeType) == "string" and self.prototypes[storeType], "Store type must be registered before loading data.")
		self:Assert(id == nil or type(id) == "string", "Store ID must be a string if provided.")
	end

	if id == nil or not self.sv[storeType][id] then
		return self:Create(storeType, id)
	elseif self.activeStores[storeType][id] then
		return self.activeStores[storeType][id]
	else
		return self:Open(storeType, id)
	end
end

function Archivist:Check(storeType, id)
	do -- arg validation
		self:Assert(type(storeType) == "string", "Expected string for storeType, got %q.", type(storeType))
		self:Assert(type(id) == "string", "Expected string for storeID, got %q.", type(id))
	end
	if self.sv[storeType] and self.sv[storeType][id] then
		return true
	else
		return false
	end
end

do -- function Archivist:Archive(data)
	local tinsert, tconcat = table.insert, table.concat
	-- serialized string looks like
	-- <obj1>,<obj2>,...,<objN>,<value>
	-- (in most cases <value> will be just &1)
	-- <objN> is a series of 0 or more ^<value>:<value> pairs
	-- the contents of the string between ^ or : and the next magic character is a string,
	-- unless the first char is the magic #, in which case it is a number.
	-- @ becomes boolean true, $ becomes false
	-- &N is a reference to <objN>
	-- when deserializing, the result of <value> is our result
	local function replace(c) return "\\"..c end
	local function serialize(object)
		local seenObjects = {}
		local serializedObjects = {}
		local function inner(val)
			local valType = type(val)
			if valType == "boolean" then
				return val and "@" or "$"
			elseif valType == "number" then
				return "#" .. val
			elseif valType == "string" then
				-- escape all characters that might be confused as magic otherwise
				return (val:gsub("[\\&,^@$#:]", replace))
			elseif valType == "table" then
				if not seenObjects[val] then
					-- cross referencing is a thing. Not to hard to serialize but do be careful
					local index = #serializedObjects + 1
					seenObjects[val] = index
					local serialized = {}
					serializedObjects[index] = "" -- so that later inserts go to the correct spot
					for k,v in pairs(val) do
						local key, value = inner(k), inner(v)
						if key ~= nil and value ~= nil then
							tinsert(serialized, "^" .. inner(k))
							tinsert(serialized, ":" .. inner(v))
						end
					end
					serializedObjects[index] = tconcat(serialized)
				end
				return "&" .. seenObjects[val]
			end
		end
		tinsert(serializedObjects, inner(object))
		-- ensure that serialized data ends with a comma
		tinsert(serializedObjects, "")
		return tconcat(serializedObjects, ',')
	end

	function Archivist:Archive(data)
		local serialized = serialize(data)
		local compressed = LibDeflate:CompressDeflate(serialized)
		local encoded = LibDeflate:EncodeForPrint(compressed)
		return encoded
	end
end

do -- function Archivist:DeArchive(encoded)
	local escape2unused = {
		["\\"] = "\001",
		["&"] = "\002",
		[","] = "\003",
		["^"] = "\004",
		["@"] = "\005",
		["$"] = "\006",
		["#"] = "\007",
		[":"] = "\008",
	}
	local unused2Escape = tInvert(escape2unused)
	local unused = "[\001-\008]"
	local function unusify(c)
		return escape2unused[c] or c
	end
	local function escapify(c)
		return unused2Escape[c] or c
	end
	local function parse(value, objectList)
		local firstChar = value:sub(1,1)
		local remainder = value:sub(2)
		if firstChar == "@" then
			return true, "BOOL", remainder
		elseif firstChar == "$" then
			return false, "BOOL", remainder
		elseif firstChar == "#" then
			local num, rest = remainder:match("([^\\&,^@$#:]*)(.*)")
			return tonumber(num), "NUMBER", rest
		elseif firstChar == "^" then
			local str, rest = remainder:match("([^:^,]*)(.*)")
			local key = parse(str, objectList)
			return key, "KEY", rest
		elseif firstChar == ":" then
			local str, rest = remainder:match("([^:^,]*)(.*)")
			local val = parse(str, objectList)
			return val, "VALUE", rest
		elseif firstChar == "&" then
			local num, rest = remainder:match("([^\\&,^@$#:]*)(.*)")
			return objectList[tonumber(num)], "OBJECT", rest
		else
			local str, rest = value:match("([^\\&,^@$#:]*)(.*)")
			return str:gsub(unused, escapify), "STRING", rest
		end
	end
	local function deserialize(value)
		-- first, convert escaped magic characters to chars that we'll likely never find naturally
		value = value:gsub("\\([\\&,^@$#:])", unusify)
		-- then, split by comma to get a list of objects
		local serializedObjects = {}
		for piece in value:gmatch("([^,]*),") do
			table.insert(serializedObjects, piece)
		end
		local objects = {}
		-- create one empty object for each object in the list
		for i = 1, #serializedObjects - 1 do
			objects[i] = {}
		end
		for index = 1, #serializedObjects - 1 do
			local str = serializedObjects[index]
			local object = objects[index]
			local mode = "KEY"
			local key
			local newValue, valueType
			while #str > 0 do
				newValue, valueType, str = parse(str, objects)
				Archivist:Assert(valueType == mode, "Encountered unexpected token type while parsing object. Expected %q but got %q.", mode, valueType)
				if valueType == "KEY" then
					key = newValue
					mode = "VALUE"
				else
					mode = "KEY"
					object[key] = newValue
				end
			end
			Archivist:Assert(mode == "KEY", "Encountered end of serialized token unexpectedly.")
		end
		local deserialized, _, remainder = parse(serializedObjects[#serializedObjects], objects)
		Archivist:Assert(#remainder == 0, "Unexpected token at end of serialized string. Expected EOF, got %q.", remainder:sub(1,10))
		return deserialized
	end

	function Archivist:DeArchive(encoded)
		local compressed = LibDeflate:DecodeForPrint(encoded)
		local serialized = LibDeflate:DecompressDeflate(compressed)
		local data = deserialize(serialized)
		return data
	end
end