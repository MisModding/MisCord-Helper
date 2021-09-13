-- ---------------------------------------------------------------------------------------------- --
--                                            ~ MisDB ~                                           --
-- ---------------------------------------------------------------------------------------------- --

--[[
MisDB Provides Mods With a Method for "Data Persistance"
Via JSON File Backed "Pages" and "Collections".
Based on a Module to Providing a "Pure Lua" implementation
'Similar' to flatDB/NoDB

MisDB Takes a Lua Table Converts it to JSON, and we call that a "Page"
These "Pages" are Grouped into Named "Collections" and Stored as Seperate Files,
One for Each Different Collection in a Folder with this "MisDB Objects" Name
And Placed in the Specified Base Directory (Relative to Your Server Root)
eg:

For a MisDB Called "MyModsData" with a Collection Named "Settings"
and Stored in the BaseDir "MisDBdata" :
    [ServerRoot]>{BaseDir}/{MisDB Name}/{Collection Name}
        ServerRoot>/MisDBdata/MyModsData/Settings


Methods:

*    MisDB:Create(BaseDir, Name) ~> TableObject(Your Main MisDB Object)
        Creates a New MisDB Object to Store Collections Backed by files in
        [ServerRoot]>{BaseDir}/{Name}

With the Returned {Object} then:
*    {Object}:Collection(Name) ~> CollectionObject(Table/Object defining this Collection)
        Create/Fetch a New Collection in this MisDB (Non Existant Collections Are autoCreated)

the Returned {Collection} then provides the following Methods:
*    {Collection}:GetPage(pageId)
        Fetch The Contents of a "Page" from this "Collection" By Specified PageID
        ! This Will return nil, with a message as the Second return var if the Page Does Not Exist
*    {Collection}:SetPage(pageId,data)
        Set The Contents of a "Page" from this "Collection" By Specified PageID
        ? Returns the "written to disk" Copy of the Page Content you Set
        ? Use this to save your page data and use the return to verify against your data
*    {Collection}:PurgePage(pageId)
        Remove a "Page" from this "Collection" By Specified PageID
        ? returns true/nil and a message with the result

]]
--! You "Should" be Using the GetPage/SetPage functions and Editing your
--! Collection a Page at a Time  using Local Copies, helps Performance(less I/O Calls)
--! Provides some Protection from any invalid Writes if you allways check the pagedata

---@class MisDB
---@field db table 'Internal DataSchema'
MisDB = {}

local function isFile(path)
    local f = io.open(path, "r")
    if f then
        f:close()
        return true
    end
    return false
end

local function isDir(path)
    path = string.gsub(path .. "/", "//", "/")
    local ok, err, code = os.rename(path, path)
    if ok or code == 13 then
        return true
    end
    return false
end

local function mkDir(path)
    local ok, Result = os.execute("mkdir " .. path:gsub("/", "\\"))
    if not ok then
        return nil, "Failed to Create " .. path .. " Directory! - " .. Result
    else
        return true, "Successfully Created " .. path .. " Directory!"
    end
end

local function dumpTable(o)
    if type(o) == "table" then
        local s = "{ "
        for k, v in pairs(o) do
            if type(k) ~= "number" then
                k = '"' .. k .. '"'
            end
            s = s .. "[" .. k .. "] = " .. dumpTable(v) .. ","
        end
        return s .. "} "
    else
        if type(o) == "string" then
            return '"' .. tostring(o) .. '"'
        else
            if type(o) == "function" then
                return '"' .. string.dump(o) .. '"'
            else
                return tostring(o)
            end
        end
    end
end

local json = {}
-- Internal functions.
local function kind_of(obj)
    if type(obj) ~= "table" then
        return type(obj)
    end
    local i = 1
    for _ in pairs(obj) do
        if obj[i] ~= nil then
            i = i + 1
        else
            return "table"
        end
    end
    if i == 1 then
        return "table"
    else
        return "array"
    end
end

local function escape_str(s)
    local in_char = {"\\", '"', "/", "\b", "\f", "\n", "\r", "\t"}
    local out_char = {"\\", '"', "/", "b", "f", "n", "r", "t"}
    for i, c in ipairs(in_char) do
        s = s:gsub(c, "\\" .. out_char[i])
    end
    return s
end

-- Returns pos, did_find; there are two cases:
-- 1. Delimiter found: pos = pos after leading space + delim; did_find = true.
-- 2. Delimiter not found: pos = pos after leading space;     did_find = false.
-- This throws an error if err_if_missing is true and the delim is not found.
local function skip_delim(str, pos, delim, err_if_missing)
    pos = pos + #str:match("^%s*", pos)
    if str:sub(pos, pos) ~= delim then
        if err_if_missing then
            error("Expected " .. delim .. " near position " .. pos)
        end
        return pos, false
    end
    return pos + 1, true
end

-- Expects the given pos to be the first character after the opening quote.
-- Returns val, pos; the returned pos is after the closing quote character.
local function parse_str_val(str, pos, val)
    val = val or ""
    local early_end_error = "End of input found while parsing string."
    if pos > #str then
        error(early_end_error)
    end
    local c = str:sub(pos, pos)
    if c == '"' then
        return val, pos + 1
    end
    if c ~= "\\" then
        return parse_str_val(str, pos + 1, val .. c)
    end
    -- We must have a \ character.
    local esc_map = {b = "\b", f = "\f", n = "\n", r = "\r", t = "\t"}
    local nextc = str:sub(pos + 1, pos + 1)
    if not nextc then
        error(early_end_error)
    end
    return parse_str_val(str, pos + 2, val .. (esc_map[nextc] or nextc))
end

-- Returns val, pos; the returned pos is after the number's final character.
local function parse_num_val(str, pos)
    local num_str = str:match("^-?%d+%.?%d*[eE]?[+-]?%d*", pos)
    local val = tonumber(num_str)
    if not val then
        error("Error parsing number at position " .. pos .. ".")
    end
    return val, pos + #num_str
end

-- Public values and functions.

function json.stringify(obj, as_key)
    local s = {} -- We'll build the string as an array of strings to be concatenated.
    local kind = kind_of(obj) -- This is 'array' if it's an array or type(obj) otherwise.
    if kind == "array" then
        if as_key then
            error("Can't encode array as key.")
        end
        s[#s + 1] = "["
        for i, val in ipairs(obj) do
            if i > 1 then
                s[#s + 1] = ", "
            end
            s[#s + 1] = json.stringify(val)
        end
        s[#s + 1] = "]"
    elseif kind == "table" then
        if as_key then
            error("Can't encode table as key.")
        end
        s[#s + 1] = "{"
        for k, v in pairs(obj) do
            if #s > 1 then
                s[#s + 1] = ", "
            end
            s[#s + 1] = json.stringify(k, true)
            s[#s + 1] = ":"
            s[#s + 1] = json.stringify(v)
        end
        s[#s + 1] = "}"
    elseif kind == "string" then
        return '"' .. escape_str(obj) .. '"'
    elseif kind == "number" then
        if as_key then
            return '"' .. tostring(obj) .. '"'
        end
        return tostring(obj)
    elseif kind == "boolean" then
        return tostring(obj)
    elseif kind == "nil" then
        return "null"
    else
        error("Unjsonifiable type: " .. kind .. ".")
    end
    return table.concat(s)
end

json.null = {} -- This is a one-off table to represent the null value.

function json.parse(str, pos, end_delim)
    pos = pos or 1
    if pos > #str then
        error("Reached unexpected end of input.")
    end
    local pos = pos + #str:match("^%s*", pos) -- Skip whitespace.
    local first = str:sub(pos, pos)
    if first == "{" then -- Parse an object.
        local obj, key, delim_found = {}, true, true
        pos = pos + 1
        while true do
            key, pos = json.parse(str, pos, "}")
            if key == nil then
                return obj, pos
            end
            if not delim_found then
                error("Comma missing between object items.")
            end
            pos = skip_delim(str, pos, ":", true) -- true -> error if missing.
            obj[key], pos = json.parse(str, pos)
            pos, delim_found = skip_delim(str, pos, ",")
        end
    elseif first == "[" then -- Parse an array.
        local arr, val, delim_found = {}, true, true
        pos = pos + 1
        while true do
            val, pos = json.parse(str, pos, "]")
            if val == nil then
                return arr, pos
            end
            if not delim_found then
                error("Comma missing between array items.")
            end
            arr[#arr + 1] = val
            pos, delim_found = skip_delim(str, pos, ",")
        end
    elseif first == '"' then -- Parse a string.
        return parse_str_val(str, pos + 1)
    elseif first == "-" or first:match("%d") then -- Parse a number.
        return parse_num_val(str, pos)
    elseif first == end_delim then -- End of an object or array.
        return nil, pos + 1
    else -- Parse true, false, or null.
        local literals = {
            ["true"] = true,
            ["false"] = false,
            ["null"] = json.null
        }
        for lit_str, lit_val in pairs(literals) do
            local lit_end = pos + #lit_str - 1
            if str:sub(pos, lit_end) == lit_str then
                return lit_val, lit_end + 1
            end
        end
        local pos_info_str = "position " .. pos .. ": " .. str:sub(pos, pos + 10)
        error("Invalid json syntax starting at " .. pos_info_str)
    end
end
JSON = json
local function load_page(path)
	local ret
	local f = io.open(path, "rb")
	if f then
		ret = JSON.parse(f:read("*a"))
		f:close()
	end
	return ret
end
local function store_page(path, page)
	if type(page) == "table" then
		local f = io.open(path, "wb")
		if f then
			f:write(JSON.stringify(page))
			f:close()
			return true
		end
	end
	return false
end
local pool = {}
local db_funcs = {
	save = function(db, p)
		if p then
			if type(p) == "string" and type(db[p]) == "table" then
				return store_page(pool[db] .. "/" .. p, db[p])
			else
				return false
			end
		end
		for p, page in pairs(db) do
			if not store_page(pool[db] .. "/" .. p, page) then
				return false
			end
		end
		return true
	end
}
local mt = {
	__index = function(db, k)
		if db_funcs[k] then
			return db_funcs[k]
		end
		if isFile(pool[db] .. "/" .. k) then
			db[k] = load_page(pool[db] .. "/" .. k)
		end
		return rawget(db, k)
	end
}
pool.hack = db_funcs
MisDB.dbcontroller =
	setmetatable(
	pool,
	{
		__mode = "kv",
		__call = function(pool, path)
			assert(isDir(path), path .. " is not a directory.")
			if pool[path] then
				return pool[path]
			end
			local db = {}
			setmetatable(db, mt)
			pool[path] = db
			pool[db] = path
			return db
		end
	}
)


--* Creates a New MisDB Object
--? MisDB Object data Stored in ServerRoot>/{BaseDir}/{Name}
--@Name     string  Name for this MisDB Object
--@BaseDir  string  Base Directory for MisDB Data
--! Allways include the final "/" in your Path
function MisDB:Create(BaseDir, Name)
    local this = {
    }
    if (type(Name) == "string") and (Name ~= "") then
        this.__NAME__ = Name
    else
        return nil, "You Must give the MisDB a Name"
    end
    if (type(BaseDir) ~= "string") or (BaseDir == "") then
        return nil, "You Must provide the Base Directory to store your MisDB data"
    end
    if not isDir(BaseDir) then
        mkDir(BaseDir)
    end
    if not isDir(BaseDir .. this.__NAME__) then
        mkDir(BaseDir .. this.__NAME__)
    end
    for k, v in pairs(MisDB) do
        this[k] = v
    end
    this.db = MisDB.dbcontroller(BaseDir .. this.__NAME__)
    return this
end

--* Saves The data Linked to this MisDB Object
function MisDB:Save()
    self.db:save()
end

--* Returns a MisDB Collection Object With Get/Set methods for accessing it
--? MisDB Collection are Stored @ ServerRoot/{BaseDir}/{MisDB Name}/{TableName}
--? As a JSON file with no file ext
--! if a collection does not exist its automaticaly created along with its table file
---@param collection_name string  Name of collection to Fetch
function MisDB:Collection(collection_name)
    -- If This Collection Doesn't Exist Create it
    if not self.db[collection_name] then
        self.db[collection_name] = {}
    end

    ---@class MisDB.Collection
    ---@field parent MisDB 'Collection MisDB Parent'
    -- MisDB Collection
    local Collection = {}
    -- Set the Name
    Collection.Name = collection_name
    -- Assign Ourselves as the objects "Parent" for access to our Methods
    Collection.parent = self

    --* Fetch a Page From Collection using its PageID
    --? If the Page Exists then this Returns a Table Containing the Contant
    --? Stored in JSONfile  for the Specified Page.
    --! Theres no Specific Method for Checking the Existance of a Page
    --! if this Function returns no Data then that Page is Empty or Missing
    Collection.GetPage = function(self, pageId)
        local PageData = self.parent.db[self.Name]
        if PageData ~= nil or {} then
            if PageData[tostring(pageId)] ~= nil then
                return PageData[tostring(pageId)]
            end
        end
        -- Something Went Wrong
        --? Invalid Page was Probably Requested
        --? Its also possible we Recieved Malformed Data the JSON Module was unable to decode
        return nil, "Failed to fetch Page: " .. tostring(pageId)
    end

    --* Set a Pages Contents By PageID in this Collection
    --? Returns a Collection Containing the Contant of the Specified Page
    Collection.SetPage = function(self, pageId, data)
        local PageData = self.parent.db[self.Name]
        if PageData ~= nil then
            PageData[tostring(pageId)] = data
            self.parent.db:save()
            return PageData[tostring(pageId)]
        end
        -- Something Went Wrong
        --! This Should't Happen unless Theres File acces Problems
        --? MisDB Automaticly Creates Collection/Pages and the files that Back them
        --? Whenever You Attempt to "Set" their Data so this Shouldn't Occur
        return nil, "Failed to Update Page: " .. tostring(pageId)
    end

    --* Remove a Page By PageID from this Collection
    --? Returns a Collection Containing the Contant of the Specified Page
    Collection.PurgePage = function(self, pageId)
        local PageData = self.parent.db[self.Name]
        if PageData then
            self.parent.db[self.Name][tostring(pageId)] = nil
            if not self.parent.db[self.Name][tostring(pageId)] then
                return true, "Success Purging Page: " .. tostring(pageId)
            else
                return nil, "Failed Purging Page: " .. tostring(pageId)
            end
        end
        -- Something Went Wrong
        --! This Should't Happen unless Theres File acces Problems
        return nil, "Couldn't Purge that Page"
    end
    -- Return Our Collection
    return Collection
end

RegisterModule('MisCordHelper.Modules.MisDB',MisDB)
return MisDB