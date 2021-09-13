-- Copyright (C) 2021 MisModding
-- 
-- This file is part of Miscord-Helper.
-- 
-- Miscord-Helper is free software: you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation, either version 3 of the License, or
-- (at your option) any later version.
-- 
-- Miscord-Helper is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
-- 
-- You should have received a copy of the GNU General Public License
-- along with Miscord-Helper.  If not, see <http://www.gnu.org/licenses/>.
--
-- ───────────────────────────────────────────────────────────── COMMON TOOLS ─────
_ = nil -- ignore

if not g_Script_RunOnceCache then g_Script_RunOnceCache = {} end

function __FILE__(offset) return debug.getinfo(1 + (offset or 1), 'S').source end
function __LINE__(offset) return debug.getinfo(1 + (offset or 1), 'l').currentline end
--- trys to get the name of the function at current stack `offset`, default to the calling function
function __FUNC__(offset) return debug.getinfo(1 + (offset or 1), 'n').name end

-- @function OnlyRunOnce
---* Function Wrapper Explicitly ensures the Provided Function Only Runs Once (Does not work with anon funcs)
---@param f function
-- function to run
-- all Further parameters are passed to the Provided Function call.
function OnlyRunOnce(f, ...)
    local found
    for k, v in ipairs(g_Script_RunOnceCache) do if (v == f) then found = true end end
    if not found then
        table.insert(g_Script_RunOnceCache, f)
        return f(...)
    end
end

-- @function ServerOnly
---* Function Wrapper Explicitly ensures the Provided Function Only Runs on Server.
---@param f function
-- function to run
-- all Further parameters are passed to the Provided Function call.
function ServerOnly(f, ...) if System.IsEditor() or CryAction.IsDedicatedServer() then return f(...) end end

-- @function ClientOnly
---* Function Wrapper Explicitly ensures the Provided Function Only Runs on Client.
---@param f function
-- function to run
-- all Further parameters are passed to the Provided Function call.
function ClientOnly(f, ...) if System.IsEditor() or CryAction.IsClient() then return f(...) end end

function ScriptDir() return debug.getinfo(2).source:match('@?(.*/)') end

function isSteam64Id(query)
    if type(query) ~= 'string' then return false, 'must be a string' end
    if (string.len(query:gsub('%s', '')) ~= 17) then
        return false, 'string must be 17 characters'
    else
        local i = 1
        for c in string.gmatch(query, '.') do
            if (type(tonumber(c)) ~= 'number') then
                return false, 'failed to cast char: ' .. tostring(i) .. ' to number'
            end
            i = i + 1
        end
        return true, 'appears to be a steam id'
    end
end

--- safely escape a given string
---@param str string    string to escape
string.escape = function(str) return str:gsub('([%^%$%(%)%%%.%[%]%*%+%-%?])', '%%%1') end

--- Split a string at a given string as delimeter (defaults to a single space)
-- | local str = string.split('string | to | split', ' | ') -- split at ` | `
-- >> str = {"string", "to", "split"}
---@param str string        string to split
---@param delimiter string  optional delimiter, defaults to " "
string.split = function(str, delimiter)
    local result = {}
    local from = 1
    local delim = delimiter or ' '
    local delim_from, delim_to = string.find(str, delim, from)
    while delim_from do
        table.insert(result, string.sub(str, from, delim_from - 1))
        from = delim_to + 1
        delim_from, delim_to = string.find(str, delim, from)
    end
    table.insert(result, string.sub(str, from))
    return result
end

--- extracts key=value styled arguments from a given string
---@param str string string to extract args from
---@return table args table containing any found key=value patterns
string.kvargs = function(str)
    local t = {}
    for k, v in string.gmatch(str, '(%w+)=(%w+)') do t[k] = v end
    return t
end

--- expand a string containing any `${var}` or `$var`.
--- Substitution values should be only numbers or strings.
--- @param s string the string
--- @param subst any either a table or a function (as in `string.gsub`)
--- @return string expanded string
function string.expand(s, subst)
    local res, k = s:gsub('%${([%w_]+)}', subst)
    if k > 0 then return res end
    return (res:gsub('%$([%w_]+)', subst))
end

function string.fromHex(str) return (str:gsub('..', function(cc) return string.char(tonumber(cc, 16)) end)) end

function string.toHex(str) return (str:gsub('.', function(c) return string.format('%02X', string.byte(c)) end)) end

local charset = {}
do -- [0-9a-zA-Z]
    for c = 48, 57 do table.insert(charset, string.char(c)) end
    for c = 65, 90 do table.insert(charset, string.char(c)) end
    for c = 97, 122 do table.insert(charset, string.char(c)) end
end

---* Cleans Eccess quotes from input string
function clean_quotes(inputString)
    local result
    result = inputString:gsub('^"', ''):gsub('"$', '')
    result = result:gsub('^\'', ''):gsub('\'$', '')
    return result
end

--- generate a random string with a given length
---@param	length number num chars to generate
---@return	string
function RandomString(length)
    if not length or length <= 0 then return '' end
    math.randomseed(os.clock() ^ 5)
    return RandomString(length - 1) .. charset[math.random(1, #charset)]
end

---* Evaluate a Lua String
--- evaluates `eval_string` in Protected mode, Does nothing if the provided string
--- contains errors or is not a valid lua chunk, else returns boolean,result
---@param eval_string string
---@return boolean success
---@return any result
function eval_string(eval_string)
    if not type(eval_string) == 'string' then
        return
    else
        local eString = eval_string:gsub('%^%*', ','):gsub('%*%^', ',')
        local eval_func = function(s) return loadstring(s)() end
        return pcall(eval_func, eString)
    end
end

---* Return the Size of a Table.
-- Works with non Indexed Tables
--- @param table table  `any table to get the size of`
--- @return number      `size of the table`
function table.size(table)
    local n = 0
    for k, v in pairs(table) do n = n + 1 end
    return n
end

--- Return an array of keys of a table.
---@param tbl table `The input table.`
---@return table `The array of keys.`
function table.keys(tbl)
    local ks = {}
    for k, _ in pairs(tbl) do table.insert(ks, k) end
    return ks
end

---* Copies all the fields from the source into t and return .
-- If a key exists in multiple tables the right-most table value is used.
--- @param t table      table to update
function table.update(t, ...)
    for i = 1, select('#', ...) do
        local x = select(i, ...)
        if x then for k, v in pairs(x) do t[k] = v end end
    end
    return t
end

if not table.pack then table.pack = function(...) return {n = select('#', ...), ...} end end

function table.each(t, f) for index, value in pairs(t) do f(value, index) end end

--
-- ────────────────────────────────────────────────────── GETTERS AND SETTERS ─────
--

---* Create a function that returns the value of t[k] ,
-- | The returned function is Bound to the Provided Table,Key.
--- @param t table      table to access
--- @param k any        key to return
--- @return function returned getter function
function bind_getter(t, k)
    return function()
        if (not type(t) == 'table') then
            return nil, 'Bound object is not a table'
        elseif (t == {}) then
            return nil, 'Bound table is Empty'
        elseif (t[k] == nil) then
            return nil, 'Bound Key does not Exist'
        else
            return t[k], 'Fetched Bound Key'
        end
    end
end

---* Create a function that sets the value of t[k] ,
---| The returned function is Bound to the Provided Table,Key ,
---| The argument passed to the returned function is used as the value to set.
--- @param t table       table to access
--- @param k table       key to set
--- @return function     returned setter function
function bind_setter(t, k)
    return function(v)
        if (not type(t) == 'table') then
            return nil, 'Bound object is not a table'
        elseif (t == {}) then
            return nil, 'Bound table is Empty'
        elseif (t[k] == nil) then
            return nil, 'Bound Key does not Exist'
        else
            t[k] = v
            return true, 'Set Bound Key'
        end
    end
end

---* Create a function that returns the value of t[k] ,
---| The argument passed to the returned function is used as the Key.
--- @param t table       table to access
--- @return function     returned getter function
function getter(t)
    if (not type(t) == 'table') then
        return nil, 'Bound object is not a table'
    elseif (t == {}) then
        return nil, 'Bound table is Empty'
    else
        return function(k) return t[k] end
    end
end

---* Create a function that sets the value of t[k] ,
---| The argument passed to the returned function is used as the Key.
--- @param t table       table to access
--- @return function     returned setter function
function setter(t)
    if (not type(t) == 'table') then
        return nil, 'Bound object is not a table'
    elseif (t == {}) then
        return nil, 'Bound table is Empty'
    else
        return function(k, v)
            t[k] = v
            return true
        end
    end
end

--
-- ──────────────────────────────────────────────────────────────────── EXTRA ─────
--

--- load and execute a lua script from a given path
function RequireFile(filename)
    local oldPackagePath = package.path
    package.path = './' .. filename .. ';' .. package.path
    local obj = require(filename)
    package.path = oldPackagePath
    if obj then
        return obj, 'success loading file from ' .. filename
    else
        return nil, 'Failed to Require file from path ' .. filename
    end
end

local function import_symbol(T, k, v, libname)
    local key = rawget(T, k)
    -- warn about collisions!
    if key and k ~= '_M' and k ~= '_NAME' and k ~= '_PACKAGE' and k ~= '_VERSION' then
        Log('warning: \'%s.%s\' will not override existing symbol\n', libname, k)
        return
    end
    rawset(T, k, v)
end

local function lookup_lib(T, t)
    for k, v in pairs(T) do if v == t then return k end end
    return '?'
end

local already_imported = {}

---* take a table and 'inject' it into the local namespace.
--- @param t table
-- The Table
--- @param T  table
-- An optional destination table (defaults to callers environment)
function Import(t, T)
    T = T or _G
    if type(t) == 'string' then t = require(t) end
    local libname = lookup_lib(T, t)
    if already_imported[t] then return end
    already_imported[t] = libname
    for k, v in pairs(t) do import_symbol(T, k, v, libname) end
end

local function Invoker(links, index)
    return function(...)
        local link = links[index]
        if not link then return end
        local continue = Invoker(links, index + 1)
        local returned = link(continue, ...)
        if returned then returned(function(_, ...) continue(...) end) end
    end
end

---* used to chain multiple functions/callbacks
-- Example
-- local function TimedText (seconds, text)
--     return function (go)
--         print(text)
--         millseconds = (seconds or 1) * 1000
--         Script.SetTimerForFunction(millseconds, go)
--     end
-- end
--
-- Chain(
--     TimedText(1, 'fading in'),
--     TimedText(1, 'showing splash screen'),
--     TimedText(1, 'showing title screen'),
--     TimedText(1, 'showing demo')
-- )()
---@return function chain
-- the cretedfunction chain
function Chain(...)
    local links = {...}

    local function chain(...)
        if not (...) then return Invoker(links, 1)(select(2, ...)) end
        local offset = #links
        for index = 1, select('#', ...) do links[offset + index] = select(index, ...) end
        return chain
    end

    return chain
end

---* Serialise a Table and deseriase back again
---| supports basic functions
---@param t table|string
-- input table or string to serialise or deserialise
---@param parse boolean
-- set to true to Deserialise/Parse the provided string
---@return string|table output
-- serialised table as a string OR deserialised string as a table
function SerialiseTable(t, parse)
    local szt = {}

    local function char(c) return ('\\%3d'):format(c:byte()) end
    local function szstr(s) return ('"%s"'):format(s:gsub('[^ !#-~]', char)) end
    local function szfun(f) return 'loadstring' .. szstr(string.dump(f)) end
    local function szany(...) return szt[type(...)](...) end

    local function sztbl(t, code, var)
        for k, v in pairs(t) do
            local ks = szany(k, code, var)
            local vs = szany(v, code, var)
            code[#code + 1] = ('%s[%s]=%s'):format(var[t], ks, vs)
        end
        return '{}'
    end

    local function memo(sz)
        return function(d, code, var)
            if var[d] == nil then
                var[1] = var[1] + 1
                var[d] = ('_[%d]'):format(var[1])
                local index = #code + 1
                code[index] = '' -- reserve place during recursion
                code[index] = ('%s=%s'):format(var[d], sz(d, code, var))
            end
            return var[d]
        end
    end

    szt['nil'] = tostring
    szt['boolean'] = tostring
    szt['number'] = tostring
    szt['string'] = szstr
    szt['function'] = memo(szfun)
    szt['table'] = memo(sztbl)

    function serialize(d)
        local code = {'local _ = {}'}
        local value = szany(d, code, {0})
        code[#code + 1] = 'return ' .. value
        if #code == 2 then
            return code[2]
        else
            return table.concat(code, '\n')
        end
    end
    if not parse then
        return serialize(t)
    else
        local ret = loadstring(t)
        if ret then return ret() end
    end
end

---@alias UUID string UniqueID
--- Generate a new UUID
--- using an improved randomseed function accouning for lua 5.1 vm limitations
--- Lua 5.1 has a limitation on the bitsize meaning that when using randomseed
--- numbers over the limit get truncated or set to 1 , destroying all randomness for the run
--- uses an assumed Lua 5.1 maximim bitsize of 32.
---@return UUID, string
function UUID()
    local bitsize = 32
    local initTime = os.time()
    local function better_randomseed(seed)
        seed = math.floor(math.abs(seed))
        if seed >= (2 ^ bitsize) then
            -- integer overflow, reduce  it to prevent a bad seed.
            seed = seed - math.floor(seed / 2 ^ bitsize) * (2 ^ bitsize)
        end
        math.randomseed(seed - 2 ^ (bitsize - 1))
        return seed
    end
    local uuidSeed = better_randomseed(initTime)
    local function UUID(prefix)
        local template = 'xyxxxxxx-xxyx-xxxy-yxxx-xyxxxxxxxxxx'
        local mutator = function(c)
            local v = (c == 'x') and math.random(0, 0xf) or math.random(8, 0xb)
            return string.format('%x', v)
        end
        return string.gsub(template, '[xy]', mutator)
    end
    return UUID(), uuidSeed
end

---* bind an argument to a type and throw an error if the provided param doesnt match at runtime.
-- Note this works in reverse of the normal assert in that it returns nil if the argumens provided are valid
-- if not the it either returns true plus and error message , or if it fails to grab debug info just true.
--- @param idx number
-- positonal index of the param to bind
--- @param val any the param to bind
--- @param tp string the params bound type
--- @usage
-- local test = function(somearg,str,somearg)
-- if assert_arg(2,str,'string') then
--    return
-- end
--
-- test(nil,1,nil) -> Invalid Param in [test()]> Argument:2 Type: number Expected: string
function assert_arg(idx, val, tp)
    if type(val) ~= tp then
        local fn = debug.getinfo(2, 'n')
        local msg = 'Invalid Param in [' .. fn.name .. '()]> ' ..
                        string.format('Argument:%s Type: %q Expected: %q', tostring(idx), type(val), tp)
        local test = function() error(msg, 4) end
        local rStat, cResult = pcall(test)
        if rStat then
            return true
        else
            return true, cResult
        end
    end
end

-- >> just incase this file gets reloaded multiple times, lets not wipe out any existing cached modules
if not g_mCustomModules then g_mCustomModules = {} end
--
-- ─── CUSTOMLOADER ───────────────────────────────────────────────────────────────
--

--- Internal: loadLuaMod(modulename)
---| Loads the Specified Module by namespace , if found in _G["g_mCustomModules"]
---@param modulename string     module namespace
---@return table|string         either a table returned by this module or a string for error
local function loadLuaMod(modulename)
    local errmsg = 'Failed to Find Module'
    -- Find the Module.
    local LuaMods = _G['g_mCustomModules']
    local this_module = LuaMods[modulename]
    -- basic validation.
    if (type(this_module) == 'function') then
        -- basic test for errors.
        local testOk, testResult = pcall(this_module)
        if testOk then
            return this_module
        else
            return testResult
        end
    end
    return errmsg
end
-- Install the loader so that it's called just before the normal Lua loader
table.insert(package.loaders, 2, loadLuaMod)

-- [Usable Methods]
-- ────────────────────────────────────────────────────────────────────────────────

---* Registers a Module Table with the Custom Loader
---| returns boolean and a message on error
---@param name string Module Name
-- This is the Module Name used to Load the Registered Module
---@param this_module table Module Table
-- This table Defines your Module, same as you would return in a standard module,
---@return boolean success
---@return string errorMsg
function RegisterModule(name, this_module)
    if (type(name) ~= 'string') or (name == ('' or ' ')) then
        return false, 'Invalid Name Passed to RegisterModule, (must be a string and not empty).'
    elseif (type(this_module) ~= 'table') or (this_module == {}) then
        return false, 'Invalid Module Passed to RegisterModule, (must be a table and not empty).'
    end
    local CustomModules = _G['g_mCustomModules']

    -- Wrap the module in a function for the loader to return.
    local ModWrap = function()
        local M = this_module
        return M
    end

    -- Ensure this Module doesnt allready Exist
    if CustomModules[name] then
        return false, 'A Module allready Exists with this Name.'
    else -- all ok, attempt to push the module into package.loaded
        CustomModules[name] = ModWrap
    end

    if (CustomModules[name] == ModWrap) then -- named package matches module.
        return true, 'Module ' .. name .. ' Loaded succesfully'
    else -- somehow named package doesnt match our module, something bad happened.
        return false, 'Something went Wrong, the Loaded module didnt match as Expected.'
    end

    return nil, 'Unknown Error' -- This should never happen.
end


--
-- ───────────────────────────────────────────────────────────── CLASSBUILDER ─────
--

-- Copyright (C) 2021 MisModding
-- 
-- This file is part of Miscord-Helper.
-- 
-- Miscord-Helper is free software: you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation, either version 3 of the License, or
-- (at your option) any later version.
-- 
-- Miscord-Helper is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
-- 
-- You should have received a copy of the GNU General Public License
-- along with Miscord-Helper.  If not, see <http://www.gnu.org/licenses/>.

-- Create a new Class
local Classy = {}

Classy.KnownClasses = {}
function Classy:Create(name, base)
    ---@class Object
    local Object
    Object = {
        __index = {
            Extend = function(self)
                local obj = {super = self}
                return setmetatable(obj, Object)
            end,
        },
        __type = 'Object',
        __tostring = function(self) return getmetatable(self).__type end,
        __call = function(self, ...)
            if self['super'] and self.super['new'] then self.super.new(self, ...) end
            if self['new'] then self:new(...) end
            return self
        end,
    }
    -- handle named classes
    if name then
        -- if the class exists, return it.
        if self.KnownClasses[name] then
            return self.KnownClasses[name]
        else
            -- set the Object type
            Object.__type = name

            local obj = {}
            -- populate class definition
            if (type(base) == 'table') then for k, v in pairs(base) do obj[k] = v end end
            setmetatable(obj, Object)
            self.KnownClasses[name] = obj
            return obj
        end
    else
        return setmetatable({}, Object) ---@type Object
    end
end

local meta = {__call = function(self, ...) return self:Create(...) end}

---@type Object|fun(classname:string,object:table):Object
Class = setmetatable(Classy, meta)

function debugLog(str, data)
    if not _DEBUG then return end
    if type(data) == 'table' then str = string.expand(str, data) end
    LogWarning(str)
end

--
-- ─── LOAD COMMON RESOURCES ──────────────────────────────────────────────────────
--
Script.LoadScriptFolder('MisCordHelper/Common')
Script.LoadScriptFolder('MisCordHelper/Modules')
Script.LoadScriptFolder('MisCordHelper/Classes')

--
-- ───────────────────────────────────────────── FIX PACKAGE PATH FOR PLUGINS ─────
--
package.path = './MisCord-Helper/Plugins/?.plugin.lua;./MisCord-Helper/Plugins/?/plugin.lua;' .. package.path
