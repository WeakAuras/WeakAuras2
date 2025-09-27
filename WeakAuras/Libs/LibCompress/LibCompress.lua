----------------------------------------------------------------------------------
--
-- LibCompress.lua
--
-- Authors: jjsheets and Galmok of European Stormrage (Horde)
-- Email : sheets.jeff@gmail.com and galmok@gmail.com
-- Licence: GPL version 2 (General Public License)
-- Revision: $Revision: 83 $
-- Date: $Date: 2018-07-03 14:33:48 +0000 (Tue, 03 Jul 2018) $
----------------------------------------------------------------------------------


local LibCompress = LibStub:NewLibrary("LibCompress", 90000 + tonumber(("$Revision: 83 $"):match("%d+")))

if not LibCompress then return end

-- list of codecs in this file:
-- \000 - Never used
-- \001 - Uncompressed
-- \002 - LZW
-- \003 - Huffman


-- local is faster than global
local CreateFrame = CreateFrame
local type = type
local tostring = tostring
local select = select
local next = next
local loadstring = loadstring
local setmetatable = setmetatable
local rawset = rawset
local assert = assert
local table_insert = table.insert
local table_remove = table.remove
local table_concat = table.concat
local string_char = string.char
local string_byte = string.byte
local string_len = string.len
local string_sub = string.sub
local unpack = unpack
local pairs = pairs
local math_modf = math.modf
local bit_band = bit.band
local bit_bor = bit.bor
local bit_bxor = bit.bxor
local bit_bnot = bit.bnot
local bit_lshift = bit.lshift
local bit_rshift = bit.rshift

--------------------------------------------------------------------------------
-- Cleanup

local tables = {} -- tables that may be cleaned have to be kept here
local tables_to_clean = {} -- list of tables by name (string) that may be reset to {} after a timeout

-- tables that may be erased
local function cleanup()
	for k,v in pairs(tables_to_clean) do
		tables[k] = {}
		tables_to_clean[k] = nil
	end
end

local timeout = -1
local function onUpdate(frame, elapsed)
	frame:Hide()
	timeout = timeout - elapsed
	if timeout <= 0 then
		cleanup()
	end
end

LibCompress.frame = LibCompress.frame or CreateFrame("frame", nil, UIParent) -- reuse the old frame
LibCompress.frame:SetScript("OnUpdate", onUpdate)
LibCompress.frame:Hide()

local function setCleanupTables(...)
	timeout = 15 -- empty tables after 15 seconds
	if not LibCompress.frame:IsShown() then
		LibCompress.frame:Show()
	end
	for i = 1, select("#",...) do
		tables_to_clean[(select(i, ...))] = true
	end
end

----------------------------------------------------------------------
----------------------------------------------------------------------
--
-- compression algorithms

--------------------------------------------------------------------------------
-- LZW codec
-- implemented by sheets.jeff@gmail.com

-- encode is used to uniquely encode a number into a sequence of bytes that can be decoded using decode()
-- the bytes returned by this do not contain "\000"
local bytes = {}
local function encode(x)
	for k = 1, #bytes do
		bytes[k] = nil
	end

	bytes[#bytes + 1] = x % 255
	x=math.floor(x/255)

	while x > 0 do
		bytes[#bytes + 1] = x % 255
		x=math.floor(x/255)
	end
	if #bytes == 1 and bytes[1] > 0 and bytes[1] < 250 then
		return string_char(bytes[1])
	else
		for i = 1, #bytes do
			bytes[i] = bytes[i] + 1
		end
		return string_char(256 - #bytes, unpack(bytes))
	end
end

--decode converts a unique character sequence into its equivalent number, from ss, beginning at the ith char.
-- returns the decoded number and the count of characters used in the decode process.
local function decode(ss, i)
	i = i or 1
	local a = string_byte(ss, i, i)
	if a > 249 then
		local r = 0
		a = 256 - a
		for n = i + a, i + 1, -1 do
			r = r * 255 + string_byte(ss, n, n) - 1
		end
		return r, a + 1
	else
		return a, 1
	end
end

-- Compresses the given uncompressed string.
-- Unless the uncompressed string starts with "\002", this is guaranteed to return a string equal to or smaller than
-- the passed string.
-- the returned string will only contain "\000" characters in rare circumstances, and will contain none if the
-- source string has none.
local dict = {}
function LibCompress:CompressLZW(uncompressed)
	if type(uncompressed) == "string" then
		local dict_size = 256
		for k in pairs(dict) do
			dict[k] = nil
		end

		local result = {"\002"}
		local w = ''
		local ressize = 1

		for i = 0, 255 do
			dict[string_char(i)] = i
		end

		for i = 1, #uncompressed do
			local c = uncompressed:sub(i, i)
			local wc = w..c
			if dict[wc] then
				w = wc
			else
				dict[wc] = dict_size
				dict_size = dict_size + 1
				local r = encode(dict[w])
				ressize = ressize + #r
				result[#result + 1] = r
				w = c
			end
		end

		if w then
			local r = encode(dict[w])
			ressize = ressize + #r
			result[#result + 1] = r
		end

		if (#uncompressed + 1) > ressize then
			return table_concat(result)
		else
			return string_char(1)..uncompressed
		end
	else
		return nil, "Can only compress strings"
	end
end

-- if the passed string is a compressed string, this will decompress it and return the decompressed string.
-- Otherwise it return an error message
-- compressed strings are marked by beginning with "\002"
function LibCompress:DecompressLZW(compressed)
	if type(compressed) == "string" then
		if compressed:sub(1, 1) ~= "\002" then
			return nil, "Can only decompress LZW compressed data ("..tostring(compressed:sub(1, 1))..")"
		end

		compressed = compressed:sub(2)
		local dict_size = 256

		for k in pairs(dict) do
			dict[k] = nil
		end

		for i = 0, 255 do
			dict[i] = string_char(i)
		end

		local result = {}
		local t = 1
		local delta, k
		k, delta = decode(compressed, t)
		t = t + delta
		result[#result + 1] = dict[k]

		local w = dict[k]
		local entry
		while t <= #compressed do
			k, delta = decode(compressed, t)
			t = t + delta
			entry = dict[k] or (w..w:sub(1, 1))
			result[#result + 1] = entry
			dict[dict_size] = w..entry:sub(1, 1)
			dict_size = dict_size + 1
			w = entry
		end
		return table_concat(result)
	else
		return nil, "Can only uncompress strings"
	end
end


--------------------------------------------------------------------------------
-- Huffman codec
-- implemented by Galmok of European Stormrage (Horde), galmok@gmail.com

local function addCode(tree, bcode, length)
	if tree then
		tree.bcode = bcode
		tree.blength = length
		if tree.c1 then
			addCode(tree.c1, bit_bor(bcode, bit_lshift(1, length)), length + 1)
		end
		if tree.c2 then
			addCode(tree.c2, bcode, length + 1)
		end
	end
end

local function escape_code(code, length)
	local escaped_code = 0
	local b
	local l = 0
	for i = length -1, 0, - 1 do
		b = bit_band(code, bit_lshift(1, i)) == 0 and 0 or 1
		escaped_code = bit_lshift(escaped_code, 1 + b) + b
		l = l + b
	end
	if length + l > 32 then
		return nil, "escape overflow ("..(length + l)..")"
	end
	return escaped_code, length + l
end

tables.Huffman_compressed = {}
tables.Huffman_large_compressed = {}

local compressed_size = 0
local remainder
local remainder_length
local function addBits(tbl, code, length)
	if remainder_length+length >= 32 then
		-- we have at least 4 bytes to store; bulk it
		remainder = remainder + bit_lshift(code, remainder_length) -- this overflows! Top part of code is lost (but we handle it below)
		-- remainder now holds 4 full bytes to store. So lets do it.
		compressed_size = compressed_size + 1
		tbl[compressed_size] = string_char(bit_band(remainder, 255)) ..
			string_char(bit_band(bit_rshift(remainder, 8), 255)) ..
			string_char(bit_band(bit_rshift(remainder, 16), 255)) ..
			string_char(bit_band(bit_rshift(remainder, 24), 255))
		remainder = 0
		code = bit_rshift(code, 32 - remainder_length)
		length =  remainder_length + length - 32
		remainder_length = 0
	end
	if remainder_length+length >= 16 then
		-- we have at least 2 bytes to store; bulk it
		remainder = remainder + bit_lshift(code, remainder_length)
		remainder_length = length + remainder_length
		-- remainder now holds at least 2 full bytes to store. So lets do it.
		compressed_size = compressed_size + 1
		tbl[compressed_size] = string_char(bit_band(remainder, 255)) .. string_char(bit_band(bit_rshift(remainder, 8), 255))
		remainder = bit_rshift(remainder, 16)
		code = remainder
		length = remainder_length - 16
		remainder = 0
		remainder_length = 0
	end
	remainder = remainder + bit_lshift(code, remainder_length)
	remainder_length = length + remainder_length
	if remainder_length >= 8 then
		compressed_size = compressed_size + 1
		tbl[compressed_size] = string_char(bit_band(remainder, 255))
		remainder = bit_rshift(remainder, 8)
		remainder_length = remainder_length -8
	end
end

-- word size for this huffman algorithm is 8 bits (1 byte).
-- this means the best compression is representing 1 byte with 1 bit, i.e. compress to 0.125 of original size.
function LibCompress:CompressHuffman(uncompressed)
	if type(uncompressed) ~= "string" then
		return nil, "Can only compress strings"
	end
	if #uncompressed == 0 then
		return "\001"
	end

	-- make histogram
	local hist = {}
	-- don't have to use all data to make the histogram
	local uncompressed_size = string_len(uncompressed)
	local c
	for i = 1, uncompressed_size do
		c = string_byte(uncompressed, i)
		hist[c] = (hist[c] or 0) + 1
	end

	--Start with as many leaves as there are symbols.
	local leafs = {}
	local leaf
	local symbols = {}
	for symbol, weight in pairs(hist) do
		leaf = { symbol=string_char(symbol), weight=weight }
		symbols[symbol] = leaf
		table_insert(leafs, leaf)
	end

	-- Enqueue all leaf nodes into the first queue (by probability in increasing order,
	-- so that the least likely item is in the head of the queue).
	sort(leafs, function(a, b)
		if a.weight < b.weight then
			return true
		elseif a.weight > b.weight then
			return false
		else
			return nil
		end
	end)

	local nLeafs = #leafs

	-- create tree
	local huff = {}
	--While there is more than one node in the queues:
	local length, height, li, hi, leaf1, leaf2
	local newNode
	while (#leafs + #huff > 1) do
		-- Dequeue the two nodes with the lowest weight.
		-- Dequeue first
		if not next(huff) then
			li, leaf1 = next(leafs)
			table_remove(leafs, li)
		elseif not next(leafs) then
			hi, leaf1 = next(huff)
			table_remove(huff, hi)
		else
			li, length = next(leafs)
			hi, height = next(huff)
			if length.weight <= height.weight then
				leaf1 = length
				table_remove(leafs, li)
			else
				leaf1 = height
				table_remove(huff, hi)
			end
		end

		-- Dequeue second
		if not next(huff) then
			li, leaf2 = next(leafs)
			table_remove(leafs, li)
		elseif not next(leafs) then
			hi, leaf2 = next(huff)
			table_remove(huff, hi)
		else
			li, length = next(leafs)
			hi, height = next(huff)
			if length.weight <= height.weight then
				leaf2 = length
				table_remove(leafs, li)
			else
				leaf2 = height
				table_remove(huff, hi)
			end
		end

		--Create a new internal node, with the two just-removed nodes as children (either node can be either child) and the sum of their weights as the new weight.
		newNode = {
			c1 = leaf1,
			c2 = leaf2,
			weight = leaf1.weight + leaf2.weight
		}
		table_insert(huff,newNode)
	end

	if #leafs > 0 then
		li, length = next(leafs)
		table_insert(huff, length)
		table_remove(leafs, li)
	end
	huff = huff[1]

	-- assign codes to each symbol
	-- c1 = "0", c2 = "1"
	-- As a common convention, bit '0' represents following the left child and bit '1' represents following the right child.
	-- c1 = left, c2 = right

	addCode(huff, 0, 0)
	if huff then
		huff.bcode = 0
		huff.blength = 1
	end

	-- READING
	-- bitfield = 0
	-- bitfield_len = 0
	-- read byte1
	-- bitfield = bitfield + bit_lshift(byte1, bitfield_len)
	-- bitfield_len = bitfield_len + 8
	-- read byte2
	-- bitfield = bitfield + bit_lshift(byte2, bitfield_len)
	-- bitfield_len = bitfield_len + 8
	-- (use 5 bits)
	--	word = bit_band( bitfield, bit_lshift(1,5)-1)
	--	bitfield = bit_rshift( bitfield, 5)
	--	bitfield_len = bitfield_len - 5
	-- read byte3
	-- bitfield = bitfield + bit_lshift(byte3, bitfield_len)
	-- bitfield_len = bitfield_len + 8

	-- WRITING
	remainder = 0
	remainder_length = 0

	local compressed = tables.Huffman_compressed
	--compressed_size = 0

	-- first byte is version info. 0 = uncompressed, 1 = 8 - bit word huffman compressed
	compressed[1] = "\003"

	-- Header: byte 0 = #leafs, bytes 1-3 = size of uncompressed data
	-- max 2^24 bytes
	length = string_len(uncompressed)
	compressed[2] = string_char(bit_band(nLeafs -1, 255))	-- number of leafs
	compressed[3] = string_char(bit_band(length, 255))			-- bit 0-7
	compressed[4] = string_char(bit_band(bit_rshift(length, 8), 255))	-- bit 8-15
	compressed[5] = string_char(bit_band(bit_rshift(length, 16), 255))	-- bit 16-23
	compressed_size = 5

	-- create symbol/code map
	local escaped_code, escaped_code_len, success, msg
	for symbol, leaf in pairs(symbols) do
		addBits(compressed, symbol, 8)
		escaped_code, escaped_code_len = escape_code(leaf.bcode, leaf.blength)
		if not escaped_code then
			return nil, escaped_code_len
		end
		addBits(compressed, escaped_code, escaped_code_len)
		addBits(compressed, 3, 2)
	end

	-- create huffman code
	local large_compressed = tables.Huffman_large_compressed
	local large_compressed_size = 0
	local ulimit
	for i = 1, length, 200 do
		ulimit = length < (i + 199) and length or (i + 199)

		for sub_i = i, ulimit do
			c = string_byte(uncompressed, sub_i)
			addBits(compressed, symbols[c].bcode, symbols[c].blength)
		end

		large_compressed_size = large_compressed_size + 1
		large_compressed[large_compressed_size] = table_concat(compressed, "", 1, compressed_size)
		compressed_size = 0
	end

	-- add remaining bits (if any)
	if remainder_length > 0 then
		large_compressed_size = large_compressed_size + 1
		large_compressed[large_compressed_size] = string_char(remainder)
	end
	local compressed_string = table_concat(large_compressed, "", 1, large_compressed_size)

	-- is compression worth it? If not, return uncompressed data.
	if (#uncompressed + 1) <= #compressed_string then
		return "\001"..uncompressed
	end

	setCleanupTables("Huffman_compressed", "Huffman_large_compressed")
	return compressed_string
end

-- lookuptable (cached between calls)
local lshiftMask = {}
setmetatable(lshiftMask, {
	__index = function (t, k)
		local v = bit_lshift(1, k)
		rawset(t, k, v)
		return v
	end
})

-- lookuptable (cached between calls)
local lshiftMinusOneMask = {}
setmetatable(lshiftMinusOneMask, {
	__index = function (t, k)
		local v = bit_lshift(1, k) -  1
		rawset(t, k, v)
		return v
	end
})

local function bor64(valueA_high, valueA, valueB_high, valueB)
	return bit_bor(valueA_high, valueB_high),
		bit_bor(valueA, valueB)
end

local function band64(valueA_high, valueA, valueB_high, valueB)
	return bit_band(valueA_high, valueB_high),
		bit_band(valueA, valueB)
end

local function lshift64(value_high, value, lshift_amount)
	if lshift_amount == 0 then
		return value_high, value
	end
	if lshift_amount >= 64 then
		return 0, 0
	end
	if lshift_amount < 32 then
		return bit_bor(bit_lshift(value_high, lshift_amount), bit_rshift(value, 32-lshift_amount)),
			bit_lshift(value, lshift_amount)
	end
	-- 32-63 bit shift
	return bit_lshift(value, lshift_amount), -- builtin modulus 32 on shift amount
		0
end

local function rshift64(value_high, value, rshift_amount)
	if rshift_amount == 0 then
		return value_high, value
	end
	if rshift_amount >= 64 then
		return 0, 0
	end
	if rshift_amount < 32 then
		return bit_rshift(value_high, rshift_amount),
			bit_bor(bit_lshift(value_high, 32-rshift_amount), bit_rshift(value, rshift_amount))
	end
	-- 32-63 bit shift
	return 0,
		bit_rshift(value_high, rshift_amount)
end

local function getCode2(bitfield_high, bitfield, field_len)
	if field_len >= 2 then
		-- [bitfield_high..bitfield]: bit 0 is right most in bitfield. bit <field_len-1> is left most in bitfield_high
		local b1, b2, remainder_high, remainder
		for i = 0, field_len - 2 do
			b1 = i <= 31 and bit_band(bitfield, bit_lshift(1, i)) or bit_band(bitfield_high, bit_lshift(1, i)) -- for shifts, 32 = 0 (5 bit used)
			b2 = (i+1) <= 31 and bit_band(bitfield, bit_lshift(1, i+1)) or bit_band(bitfield_high, bit_lshift(1, i+1))
			if not (b1 == 0) and not (b2 == 0) then
				-- found 2 bits set right after each other (stop bits) with i pointing at the first stop bit
				-- return the two bitfields separated by the two stopbits (3 values for each: bitfield_high, bitfield, field_len)
				-- bits left: field_len - (i+2)
				remainder_high, remainder = rshift64(bitfield_high, bitfield, i+2)
				-- first bitfield is the lower part
				return (i-1) >= 32 and bit_band(bitfield_high, bit_lshift(1, i) - 1) or 0,
					i >= 32 and bitfield or bit_band(bitfield, bit_lshift(1, i) - 1),
					i,
					remainder_high,
					remainder,
					field_len-(i+2)
			end
		end
	end
	return nil
end

local function unescape_code(code, code_len)
	local unescaped_code = 0
	local b
	local l = 0
	local i = 0
	while i < code_len do
		b = bit_band( code, lshiftMask[i])
		if not (b == 0) then
			unescaped_code = bit_bor(unescaped_code, lshiftMask[l])
			i = i + 1
		end
		i = i + 1
		l = l + 1
	end
	return unescaped_code, l
end

tables.Huffman_uncompressed = {}
tables.Huffman_large_uncompressed = {} -- will always be as big as the largest string ever decompressed. Bad, but clearing it every time takes precious time.

function LibCompress:DecompressHuffman(compressed)
	if not type(compressed) == "string" then
		return nil, "Can only uncompress strings"
	end

	local compressed_size = #compressed
	--decode header
	local info_byte = string_byte(compressed)
	-- is data compressed
	if info_byte == 1 then
		return compressed:sub(2) --return uncompressed data
	end
	if not (info_byte == 3) then
		return nil, "Can only decompress Huffman compressed data ("..tostring(info_byte)..")"
	end

	local num_symbols = string_byte(string_sub(compressed, 2, 2)) + 1
	local c0 = string_byte(string_sub(compressed, 3, 3))
	local c1 = string_byte(string_sub(compressed, 4, 4))
	local c2 = string_byte(string_sub(compressed, 5, 5))
	local orig_size = c2 * 65536 + c1 * 256 + c0
	if orig_size == 0 then
		return ""
	end

	-- decode code -> symbol map
	local bitfield = 0
	local bitfield_high = 0
	local bitfield_len = 0
	local map = {} -- only table not reused in Huffman decode.
	setmetatable(map, {
		__index = function (t, k)
			local v = {}
			rawset(t, k, v)
			return v
		end
	})

	local i = 6 -- byte 1-5 are header bytes
	local c, cl
	local minCodeLen = 1000
	local maxCodeLen = 0
	local symbol, code_high, code, code_len, temp_high, temp, _bitfield_high, _bitfield, _bitfield_len
	local n = 0
	local state = 0 -- 0 = get symbol (8 bits),  1 = get code (varying bits, ends with 2 bits set)
	while n < num_symbols do
		if i > compressed_size then
			return nil, "Cannot decode map"
		end

		c = string_byte(compressed, i)
		temp_high, temp = lshift64(0, c, bitfield_len)
		bitfield_high, bitfield = bor64(bitfield_high, bitfield, temp_high, temp)
		bitfield_len = bitfield_len + 8

		if state == 0 then
			symbol = bit_band(bitfield, 255)
			bitfield_high, bitfield = rshift64(bitfield_high, bitfield, 8)
			bitfield_len = bitfield_len - 8
			state = 1 -- search for code now
		else
			code_high, code, code_len, _bitfield_high, _bitfield, _bitfield_len = getCode2(bitfield_high, bitfield, bitfield_len)
			if code_high then
				bitfield_high, bitfield, bitfield_len = _bitfield_high, _bitfield, _bitfield_len
				if code_len > 32 then
					return nil, "Unsupported symbol code length ("..code_len..")"
				end
				c, cl = unescape_code(code, code_len)
				map[cl][c] = string_char(symbol)
				minCodeLen = cl < minCodeLen and cl or minCodeLen
				maxCodeLen = cl > maxCodeLen and cl or maxCodeLen
				--print("symbol: "..string_char(symbol).."  code: "..tobinary(c, cl))
				n = n + 1
				state = 0 -- search for next symbol (if any)
			end
		end
		i = i + 1
	end

	-- don't create new subtables for entries not in the map. Waste of space.
	-- But do return an empty table to prevent runtime errors. (instead of returning nil)
	local mt = {}
	setmetatable(map, {
		__index = function (t, k)
			return mt
		end
	})

	local uncompressed = tables.Huffman_uncompressed
	local large_uncompressed = tables.Huffman_large_uncompressed
	local uncompressed_size = 0
	local large_uncompressed_size = 0
	local test_code
	local test_code_len = minCodeLen
	local dec_size = 0
	compressed_size = compressed_size + 1
	local temp_limit = 200 -- first limit of uncompressed data. large_uncompressed will hold strings of length 200
	temp_limit = temp_limit > orig_size and orig_size or temp_limit

	while true do
		if test_code_len <= bitfield_len then
			test_code = bit_band( bitfield, lshiftMinusOneMask[test_code_len])
			symbol = map[test_code_len][test_code]

			if symbol then
				uncompressed_size = uncompressed_size + 1
				uncompressed[uncompressed_size] = symbol
				dec_size = dec_size + 1
				if dec_size >= temp_limit then
					if dec_size >= orig_size then -- checked here for speed reasons
						break
					end
					-- process compressed bytes in smaller chunks
					large_uncompressed_size = large_uncompressed_size + 1
					large_uncompressed[large_uncompressed_size] = table_concat(uncompressed, "", 1, uncompressed_size)
					uncompressed_size = 0
					temp_limit = temp_limit + 200 -- repeated chunk size is 200 uncompressed bytes
					temp_limit = temp_limit > orig_size and orig_size or temp_limit
				end

				bitfield = bit_rshift(bitfield, test_code_len)
				bitfield_len = bitfield_len - test_code_len
				test_code_len = minCodeLen
			else
				test_code_len = test_code_len + 1
				if test_code_len > maxCodeLen then
					return nil, "Decompression error at "..tostring(i).."/"..tostring(#compressed)
				end
			end
		else
			c = string_byte(compressed, i)
			bitfield = bitfield + bit_lshift(c or 0, bitfield_len)
			bitfield_len = bitfield_len + 8
			if i > compressed_size then
				break
			end
			i = i + 1
		end
	end

	setCleanupTables("Huffman_uncompressed", "Huffman_large_uncompressed")
	return table_concat(large_uncompressed, "", 1, large_uncompressed_size)..table_concat(uncompressed, "", 1, uncompressed_size)
end

--------------------------------------------------------------------------------
-- Generic codec interface

function LibCompress:Store(uncompressed)
	if type(uncompressed) ~= "string" then
		return nil, "Can only compress strings"
	end
	return "\001"..uncompressed
end

function LibCompress:DecompressUncompressed(data)
	if type(data) ~= "string" then
		return nil, "Can only handle strings"
	end
	if string_byte(data) ~= 1 then
		return nil, "Can only handle uncompressed data"
	end
	return data:sub(2)
end

local compression_methods = {
	[2] = LibCompress.CompressLZW,
	[3] = LibCompress.CompressHuffman
}

local decompression_methods = {
	[1] = LibCompress.DecompressUncompressed,
	[2] = LibCompress.DecompressLZW,
	[3] = LibCompress.DecompressHuffman
}

-- try all compression codecs and return best result
function LibCompress:Compress(data)
	local method = next(compression_methods)
	local result = compression_methods[method](self, data)
	local n
	method = next(compression_methods, method)
	while method do
		n = compression_methods[method](self, data)
		if #n < #result then
			result = n
		end
		method = next(compression_methods, method)
	end
	return result
end

function LibCompress:Decompress(data)
	local header_info = string_byte(data)
	if decompression_methods[header_info] then
		return decompression_methods[header_info](self, data)
	else
		return nil, "Unknown compression method ("..tostring(header_info)..")"
	end
end

----------------------------------------------------------------------
----------------------------------------------------------------------
--
-- Encoding algorithms

--------------------------------------------------------------------------------
-- Prefix encoding algorithm
-- implemented by Galmok of European Stormrage (Horde), galmok@gmail.com

--[[
	Howto: Encode and Decode:

	3 functions are supplied, 2 of them are variants of the first.  They return a table with functions to encode and decode text.

	table, msg = LibCompress:GetEncodeTable(reservedChars, escapeChars,  mapChars)

		reservedChars: The characters in this string will not appear in the encoded data.
		escapeChars: A string of characters used as escape-characters (don't supply more than needed). #escapeChars >= 1
		mapChars: First characters in reservedChars maps to first characters in mapChars.  (#mapChars <= #reservedChars)

	return value:
		table
			if nil then msg holds an error message, otherwise use like this:

			encoded_message = table:Encode(message)
			message = table:Decode(encoded_message)

	GetAddonEncodeTable: Sets up encoding for the addon channel (\000 is encoded)
	GetChatEncodeTable: Sets up encoding for the chat channel (many bytes encoded, see the function for details)

	Except for the mapped characters, all encoding will be with 1 escape character followed by 1 suffix, i.e. 2 bytes.
]]
-- to be able to match any requested byte value, the search string must be preprocessed
-- characters to escape with %:
-- ( ) . % + - * ? [ ] ^ $
-- "illegal" byte values:
-- 0 is replaces %z
local gsub_escape_table = {
	['\000'] = "%z",
	[('(')] = "%(",
	[(')')] = "%)",
	[('.')] = "%.",
	[('%')] = "%%",
	[('+')] = "%+",
	[('-')] = "%-",
	[('*')] = "%*",
	[('?')] = "%?",
	[('[')] = "%[",
	[(']')] = "%]",
	[('^')] = "%^",
	[('$')] = "%$"
}

local function escape_for_gsub(str)
	return str:gsub("([%z%(%)%.%%%+%-%*%?%[%]%^%$])",  gsub_escape_table)
end

function LibCompress:GetEncodeTable(reservedChars, escapeChars, mapChars)
	reservedChars = reservedChars or ""
	escapeChars = escapeChars or ""
	mapChars = mapChars or ""

	-- select a default escape character
	if escapeChars == "" then
		return nil, "No escape characters supplied"
	end

	if #reservedChars < #mapChars then
		return nil, "Number of reserved characters must be at least as many as the number of mapped chars"
	end

	if reservedChars == "" then
		return nil, "No characters to encode"
	end

	-- list of characters that must be encoded
	local encodeBytes = reservedChars..escapeChars..mapChars

	-- build list of bytes not available as a suffix to a prefix byte
	local taken = {}
	for i = 1, string_len(encodeBytes) do
		taken[string_sub(encodeBytes, i, i)] = true
	end

	-- allocate a table to hold encode/decode strings/functions
	local codecTable = {}

	-- the encoding can be a single gsub, but the decoding can require multiple gsubs
	local decode_func_string = {}

	local encode_search = {}
	local encode_translate = {}
	local encode_func
	local decode_search = {}
	local decode_translate = {}
	local decode_func
	local c, r, to, from
	local escapeCharIndex, escapeChar = 0

	-- map single byte to single byte
	if #mapChars > 0 then
		for i = 1, #mapChars do
			from = string_sub(reservedChars, i, i)
			to = string_sub(mapChars, i, i)
			encode_translate[from] = to
			table_insert(encode_search, from)
			decode_translate[to] = from
			table_insert(decode_search, to)
		end
		codecTable["decode_search"..tostring(escapeCharIndex)] = "([".. escape_for_gsub(table_concat(decode_search)).."])"
		codecTable["decode_translate"..tostring(escapeCharIndex)] = decode_translate
		table_insert(decode_func_string, "str = str:gsub(self.decode_search"..tostring(escapeCharIndex)..", self.decode_translate"..tostring(escapeCharIndex)..");")

	end

	-- map single byte to double-byte
	escapeCharIndex = escapeCharIndex + 1
	escapeChar = string_sub(escapeChars, escapeCharIndex, escapeCharIndex)
	r = 0 -- suffix char value to the escapeChar
	decode_search = {}
	decode_translate = {}
	for i = 1, string_len(encodeBytes) do
		c = string_sub(encodeBytes, i, i)
		if not encode_translate[c] then
			-- this loop will update escapeChar and r
			while r >= 256 or taken[string_char(r)] do
				r = r + 1
				if r > 255 then -- switch to next escapeChar
					codecTable["decode_search"..tostring(escapeCharIndex)] = escape_for_gsub(escapeChar).."([".. escape_for_gsub(table_concat(decode_search)).."])"
					codecTable["decode_translate"..tostring(escapeCharIndex)] = decode_translate
					table_insert(decode_func_string, "str = str:gsub(self.decode_search"..tostring(escapeCharIndex)..", self.decode_translate"..tostring(escapeCharIndex)..");")

					escapeCharIndex  = escapeCharIndex + 1
					escapeChar = string_sub(escapeChars, escapeCharIndex, escapeCharIndex)

					if escapeChar == "" then -- we are out of escape chars and we need more!
						return nil, "Out of escape characters"
					end

					r = 0
					decode_search = {}
					decode_translate = {}
				end
			end
			encode_translate[c] = escapeChar..string_char(r)
			table_insert(encode_search, c)
			decode_translate[string_char(r)] = c
			table_insert(decode_search, string_char(r))
			r = r + 1
		end
	end

	if r > 0 then
		codecTable["decode_search"..tostring(escapeCharIndex)] = escape_for_gsub(escapeChar).."([".. escape_for_gsub(table_concat(decode_search)).."])"
		codecTable["decode_translate"..tostring(escapeCharIndex)] = decode_translate
		table_insert(decode_func_string, "str = str:gsub(self.decode_search"..tostring(escapeCharIndex)..", self.decode_translate"..tostring(escapeCharIndex)..");")
	end

	-- change last line from "str = ...;" to "return ...;";
	decode_func_string[#decode_func_string] = decode_func_string[#decode_func_string]:gsub("str = (.*);", "return %1;")
	decode_func_string = "return function(self, str) "..table_concat(decode_func_string).." end"

	encode_search = "([".. escape_for_gsub(table_concat(encode_search)).."])"
	decode_search = escape_for_gsub(escapeChars).."([".. escape_for_gsub(table_concat(decode_search)).."])"

	encode_func = assert(loadstring("return function(self, str) return str:gsub(self.encode_search, self.encode_translate); end"))()
	decode_func = assert(loadstring(decode_func_string))()
	codecTable.encode_search = encode_search
	codecTable.encode_translate = encode_translate
	codecTable.Encode = encode_func
	codecTable.decode_search = decode_search
	codecTable.decode_translate = decode_translate
	codecTable.Decode = decode_func

	codecTable.decode_func_string = decode_func_string -- to be deleted
	return codecTable
end

-- Addons: Call this only once and reuse the returned table for all encodings/decodings.
function LibCompress:GetAddonEncodeTable(reservedChars, escapeChars, mapChars )
	reservedChars = reservedChars or ""
	escapeChars = escapeChars or ""
	mapChars = mapChars or ""
	-- Following byte values are not allowed:
	-- \000
	if escapeChars == "" then
		escapeChars = "\001"
	end
	return self:GetEncodeTable( (reservedChars or "").."\000", escapeChars, mapChars)
end

-- Addons: Call this only once and reuse the returned table for all encodings/decodings.
function LibCompress:GetChatEncodeTable(reservedChars, escapeChars, mapChars)
	reservedChars = reservedChars or ""
	escapeChars = escapeChars or ""
	mapChars = mapChars or ""
	-- Following byte values are not allowed:
	-- \000, s, S, \010, \013, \124, %
	-- Because SendChatMessage will error if an UTF8 multibyte character is incomplete,
	-- all character values above 127 have to be encoded to avoid this. This costs quite a bit of bandwidth (about 13-14%)
	-- Also, because drunken status is unknown for the received, strings used with SendChatMessage should be terminated with
	-- an identifying byte value, after which the server MAY add "...hic!" or as much as it can fit(!).
	-- Pass the identifying byte as a reserved character to this function to ensure the encoding doesn't contain that value.
	--  or use this: local message, match = arg1:gsub("^(.*)\029.-$", "%1")
	--  arg1 is message from channel, \029 is the string terminator, but may be used in the encoded datastream as well. :-)
	-- This encoding will expand data anywhere from:
	-- 0% (average with pure ascii text)
	-- 53.5% (average with random data valued zero to 255)
	-- 100% (only encoding data that encodes to two bytes)
	local r = {}

	for i = 128, 255 do
		table_insert(r, string_char(i))
	end

	reservedChars = "sS\000\010\013\124%"..table_concat(r)..(reservedChars or "")
	if escapeChars == "" then
		escapeChars = "\029\031"
	end

	if mapChars == "" then
		mapChars = "\015\020";
	end
	return self:GetEncodeTable(reservedChars, escapeChars, mapChars)
end

--------------------------------------------------------------------------------
-- 7 bit encoding algorithm
-- implemented by Galmok of European Stormrage (Horde), galmok@gmail.com

-- The encoded data holds values from 0 to 127 inclusive. Additional encoding may be necessary.
-- This algorithm isn't exactly fast and be used with care and consideration

tables.encode7bit = {}

function LibCompress:Encode7bit(str)
	local remainder = 0
	local remainder_length = 0
	local tbl = tables.encode7bit
	local encoded_size = 0
	local length = #str
	for i = 1, length do
		local code = string_byte(str, i)
		remainder = remainder + bit_lshift(code, remainder_length)
		remainder_length = 8 + remainder_length
		while remainder_length >= 7 do
			encoded_size = encoded_size + 1
			tbl[encoded_size] = string_char(bit_band(remainder, 127))
			remainder = bit_rshift(remainder, 7)
			remainder_length = remainder_length -7
		end
	end

	if remainder_length > 0 then
		encoded_size = encoded_size + 1
		tbl[encoded_size] = string_char(remainder)
	end
	setCleanupTables("encode7bit")
	return table_concat(tbl, "", 1, encoded_size)
end

tables.decode8bit = {}

function LibCompress:Decode7bit(str)
	local bit8 = tables.decode8bit
	local decoded_size = 0
	local ch
	local i = 1
	local bitfield_len = 0
	local bitfield = 0
	local length = #str
	while true do
		if bitfield_len >= 8 then
			decoded_size = decoded_size + 1
			bit8[decoded_size] = string_char(bit_band(bitfield, 255))
			bitfield = bit_rshift(bitfield, 8)
			bitfield_len = bitfield_len - 8
		end
		ch = string_byte(str, i)
		bitfield=bitfield + bit_lshift(ch or 0, bitfield_len)
		bitfield_len = bitfield_len + 7
		if i > length then
			break
		end
		i = i + 1
	end
	setCleanupTables("decode8bit")
	return table_concat(bit8, "", 1, decoded_size)
end

----------------------------------------------------------------------
----------------------------------------------------------------------
--
-- Checksum/hash algorithms

--------------------------------------------------------------------------------
-- FCS16/32 checksum algorithms
-- converted from C by Galmok of European Stormrage (Horde), galmok@gmail.com
-- usage:
-- 	code = LibCompress:fcs16init()
--	code = LibCompress:fcs16update(code, data1)
--	code = LibCompress:fcs16update(code, data2)
--	code = LibCompress:fcs16update(code, data...)
--	code = LibCompress:fcs16final(code)
--
--	data = string
--	fcs16 provides a 16 bit checksum, fcs32 provides a 32 bit checksum.


--[[/* The following copyright notice concerns only the FCS hash algorithm
---------------------------------------------------------------------------
Copyright (c) 2003, Dominik Reichl <dominik.reichl@t-online.de>, Germany.
All rights reserved.

Distributed under the terms of the GNU General Public License v2.

This software is provided 'as is' with no explicit or implied warranties
in respect of its properties, including, but not limited to, correctness
and/or fitness for purpose.
---------------------------------------------------------------------------
*/]]
--// FCS-16 algorithm implemented as described in RFC 1331
local FCSINIT16 = 65535
--// Fast 16 bit FCS lookup table
local fcs16tab = { [0]=0, 4489, 8978, 12955, 17956, 22445, 25910, 29887,
	35912, 40385, 44890, 48851, 51820, 56293, 59774, 63735,
	4225, 264, 13203, 8730, 22181, 18220, 30135, 25662,
	40137, 36160, 49115, 44626, 56045, 52068, 63999, 59510,
	8450, 12427, 528, 5017, 26406, 30383, 17460, 21949,
	44362, 48323, 36440, 40913, 60270, 64231, 51324, 55797,
	12675, 8202, 4753, 792, 30631, 26158, 21685, 17724,
	48587, 44098, 40665, 36688, 64495, 60006, 55549, 51572,
	16900, 21389, 24854, 28831, 1056, 5545, 10034, 14011,
	52812, 57285, 60766, 64727, 34920, 39393, 43898, 47859,
	21125, 17164, 29079, 24606, 5281, 1320, 14259, 9786,
	57037, 53060, 64991, 60502, 39145, 35168, 48123, 43634,
	25350, 29327, 16404, 20893, 9506, 13483, 1584, 6073,
	61262, 65223, 52316, 56789, 43370, 47331, 35448, 39921,
	29575, 25102, 20629, 16668, 13731, 9258, 5809, 1848,
	65487, 60998, 56541, 52564, 47595, 43106, 39673, 35696,
	33800, 38273, 42778, 46739, 49708, 54181, 57662, 61623,
	2112, 6601, 11090, 15067, 20068, 24557, 28022, 31999,
	38025, 34048, 47003, 42514, 53933, 49956, 61887, 57398,
	6337, 2376, 15315, 10842, 24293, 20332, 32247, 27774,
	42250, 46211, 34328, 38801, 58158, 62119, 49212, 53685,
	10562, 14539, 2640, 7129, 28518, 32495, 19572, 24061,
	46475, 41986, 38553, 34576, 62383, 57894, 53437, 49460,
	14787, 10314, 6865, 2904, 32743, 28270, 23797, 19836,
	50700, 55173, 58654, 62615, 32808, 37281, 41786, 45747,
	19012, 23501, 26966, 30943, 3168, 7657, 12146, 16123,
	54925, 50948, 62879, 58390, 37033, 33056, 46011, 41522,
	23237, 19276, 31191, 26718, 7393, 3432, 16371, 11898,
	59150, 63111, 50204, 54677, 41258, 45219, 33336, 37809,
	27462, 31439, 18516, 23005, 11618, 15595, 3696, 8185,
	63375, 58886, 54429, 50452, 45483, 40994, 37561, 33584,
	31687, 27214, 22741, 18780, 15843, 11370, 7921, 3960 }

function LibCompress:fcs16init()
	return FCSINIT16
end

function LibCompress:fcs16update(uFcs16, pBuffer)
	local length = string_len(pBuffer)
	for i = 1, length do
		uFcs16 = bit_bxor(bit_rshift(uFcs16,8), fcs16tab[bit_band(bit_bxor(uFcs16, string_byte(pBuffer, i)), 255)])
	end
	return uFcs16
end

function LibCompress:fcs16final(uFcs16)
	return bit_bxor(uFcs16,65535)
end
-- END OF FCS16

--[[/*
---------------------------------------------------------------------------
Copyright (c) 2003, Dominik Reichl <dominik.reichl@t-online.de>, Germany.
All rights reserved.

Distributed under the terms of the GNU General Public License v2.

This software is provided 'as is' with no explicit or implied warranties
in respect of its properties, including, but not limited to, correctness
and/or fitness for purpose.
---------------------------------------------------------------------------
*/]]

--// FCS-32 algorithm implemented as described in RFC 1331

local FCSINIT32 = -1

--// Fast 32 bit FCS lookup table
local fcs32tab = { [0] = 0, 1996959894, -301047508, -1727442502, 124634137, 1886057615, -379345611, -1637575261,
	249268274, 2044508324, -522852066, -1747789432, 162941995, 2125561021, -407360249, -1866523247,
	498536548, 1789927666, -205950648, -2067906082, 450548861, 1843258603, -187386543, -2083289657,
	325883990, 1684777152, -43845254, -1973040660, 335633487, 1661365465, -99664541, -1928851979,
	997073096, 1281953886, -715111964, -1570279054, 1006888145, 1258607687, -770865667, -1526024853,
	901097722, 1119000684, -608450090, -1396901568, 853044451, 1172266101, -589951537, -1412350631,
	651767980, 1373503546, -925412992, -1076862698, 565507253, 1454621731, -809855591, -1195530993,
	671266974, 1594198024, -972236366, -1324619484, 795835527, 1483230225, -1050600021, -1234817731,
	1994146192, 31158534, -1731059524, -271249366, 1907459465, 112637215, -1614814043, -390540237,
	2013776290, 251722036, -1777751922, -519137256, 2137656763, 141376813, -1855689577, -429695999,
	1802195444, 476864866, -2056965928, -228458418, 1812370925, 453092731, -2113342271, -183516073,
	1706088902, 314042704, -1950435094, -54949764, 1658658271, 366619977, -1932296973, -69972891,
	1303535960, 984961486, -1547960204, -725929758, 1256170817, 1037604311, -1529756563, -740887301,
	1131014506, 879679996, -1385723834, -631195440, 1141124467, 855842277, -1442165665, -586318647,
	1342533948, 654459306, -1106571248, -921952122, 1466479909, 544179635, -1184443383, -832445281,
	1591671054, 702138776, -1328506846, -942167884, 1504918807, 783551873, -1212326853, -1061524307,
	-306674912, -1698712650, 62317068, 1957810842, -355121351, -1647151185, 81470997, 1943803523,
	-480048366, -1805370492, 225274430, 2053790376, -468791541, -1828061283, 167816743, 2097651377,
	-267414716, -2029476910, 503444072, 1762050814, -144550051, -2140837941, 426522225, 1852507879,
	-19653770, -1982649376, 282753626, 1742555852, -105259153, -1900089351, 397917763, 1622183637,
	-690576408, -1580100738, 953729732, 1340076626, -776247311, -1497606297, 1068828381, 1219638859,
	-670225446, -1358292148, 906185462, 1090812512, -547295293, -1469587627, 829329135, 1181335161,
	-882789492, -1134132454, 628085408, 1382605366, -871598187, -1156888829, 570562233, 1426400815,
	-977650754, -1296233688, 733239954, 1555261956, -1026031705, -1244606671, 752459403, 1541320221,
	-1687895376, -328994266, 1969922972, 40735498, -1677130071, -351390145, 1913087877, 83908371,
	-1782625662, -491226604, 2075208622, 213261112, -1831694693, -438977011, 2094854071, 198958881,
	-2032938284, -237706686, 1759359992, 534414190, -2118248755, -155638181, 1873836001, 414664567,
	-2012718362, -15766928, 1711684554, 285281116, -1889165569, -127750551, 1634467795, 376229701,
	-1609899400, -686959890, 1308918612, 956543938, -1486412191, -799009033, 1231636301, 1047427035,
	-1362007478, -640263460, 1088359270, 936918000, -1447252397, -558129467, 1202900863, 817233897,
	-1111625188, -893730166, 1404277552, 615818150, -1160759803, -841546093, 1423857449, 601450431,
	-1285129682, -1000256840, 1567103746, 711928724, -1274298825, -1022587231, 1510334235, 755167117 }

function LibCompress:fcs32init()
	return FCSINIT32
end

function LibCompress:fcs32update(uFcs32, pBuffer)
	local length = string_len(pBuffer)
	for i = 1, length do
		uFcs32 = bit_bxor(bit_rshift(uFcs32, 8), fcs32tab[bit_band(bit_bxor(uFcs32, string_byte(pBuffer, i)), 255)])
	end
	return uFcs32
end

function LibCompress:fcs32final(uFcs32)
	return bit_bnot(uFcs32)
end