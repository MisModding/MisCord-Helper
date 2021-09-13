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
-- ────────────────────────────────────────────────────────────────────────────── I ──────────
--   :::::: M I S C O R D   H E L P E R   M A I N : :  :   :    :     :        :          :
-- ────────────────────────────────────────────────────────────────────────────────────────
--
if (not g_MisCordHelper) then
    ---NOTE this file should only ever be loaded once... and only if g_MisCordHelper exists
    return
end

local FS = require 'MisCordHelper.Modules.FileSystem' ---@type FS
local MisDB = require 'MisCordHelper.Modules.MisDB' ---@type MisDB
local configReader = require 'MisCordHelper.Modules.configReader'
if (not g_HookManager) then g_HookManager = require 'MisCordHelper.Modules.Hooker' end

--- Main DataStore Definition
local DataStore = MisDB:Create('./Miscord-Helper/', 'PersistantStorage') ---@type MisDB

---@class PersistantStorage
local PersistantStorage = {
    --- MisCord Helper Settings
    ---@type MisDB.Collection
    Settings = DataStore:Collection('MisCord_Helper_Settings'),

    --- MisCord Helper UserData
    ---@type MisDB.Collection
    Data = DataStore:Collection('MisCord_Helper_PersistantData'),

    --- MisCord Helper Cache
    ---@type MisDB.Collection
    Cache = DataStore:Collection('MisCord_Helper_Cache'),
}

---@param PersistantStorage  PersistantStorage
function isValidPersistantStorage(PersistantStorage)
    if assert_arg(1, PersistantStorage, 'table') then return false, 'must pass persistant storage object' end
    if (not PersistantStorage['Settings']) then
        return false, 'Invalid PersistantStorage Object. must contain a [Settings] Source'
    end
    if (not PersistantStorage['Data']) then return false, 'Invalid PersistantStorage Object. must contain a [Data] Source' end
    if (not PersistantStorage['Cache']) then return false, 'Invalid PersistantStorage Object. must contain a [Cache] Source' end
    return true, 'PersistantStorage Is Valid'
end

--- MisCord Helper Plugins
g_MisCordHelper.Plugins = {} ---@type table<number,table>
--- MisCord Helper DataStore
g_MisCordHelper.PersistantStorage = PersistantStorage
--- Using MisCordHelper Logger
Logger = g_MisCordHelper.Logger

---@param self MisCord-Helper
local function createDefaultFiles(self)
    Logger.Log(__FUNC__(), 'MisCordHelper - Checking Files......')
    if (not FS.isDir('./MisCord-Helper')) then FS.mkDir('./MisCord-Helper') end
    for i, file in ipairs(self.DEFAULT_FILES) do
        if (not FS.isFile(file.file_path)) then
            Logger.Warn(__FUNC__(), string.format('File Missing: %s [ %s ] >> Creating....', file.file_name, file.file_path))
            FS.writefile(file.file_path, file.file_content)
        end
    end
end

---@param self MisCord-Helper
local function loadConfig(self)
    Logger.Log(__FUNC__(), 'MisCordHelper - Loading Config......')
    -- load existing Settings from PersistantStorage
    local config_from_persistantstorage = (self.PersistantStorage.Settings:GetPage('MisCordHelper_Config') or {})

    -- load settings from Config file
    local config_from_file = configReader.read('./MisCord-Helper/Settings.cfg')
    --- Merge Configs
    local settings = table.update({}, config_from_persistantstorage, config_from_file)

    --- Save Settings back to PersistantStorage
    self.PersistantStorage.Settings:SetPage('MisCordHelper_Config', settings)
end

local function initServerLifetimeCounter(self)
    Logger.Log(__FUNC__(), 'MisCordHelper - Initialising ServerLifeTime Counter......')
    local Timer = require 'MisCordHelper.Classes.Timer'
    local ServerCounterData = self.PersistantStorage.Settings:GetPage('ServerLifetime')
    if (not ServerCounterData) then
        ServerCounterData = {LifeTimeStart = string.format('%.f', os.time())}
        self.PersistantStorage.Settings:SetPage('ServerLifetime', ServerCounterData)
    end
    self.ServerLifetime = Timer(tonumber(ServerCounterData['LifeTimeStart'])) ---@type MisModding.simple_timer
    self.ServerLifetime:start()
end

---@param self MisCord-Helper
local function initialiseHTTPServer(self)
    Logger.Log(__FUNC__(), 'MisCordHelper - Initialising HTTPServer......')
    Script.ReloadScript('MisCordHelper/HTTPServer.lua')
    local HTTP_SERVER = require 'MisCordHelper.HTTPServer'
    self.HTTPServer = HTTP_SERVER
    Script.LoadScriptFolder('MisCordHelper/HTTP_SERVER')
    local routes_list = table.keys(self.HTTPServer['Routes']['GET'])
    local routes_str = ''
    table.each(routes_list,function(route)
        routes_str = routes_str .. string.format('[ %s ]\n',route)
    end)
    Logger.Log(__FUNC__(), string.format('MisCordHelper - Registered  HTTPServer Routes: \n%s', routes_str))
    self.HTTPServer:use()
end

---@param self MisCord-Helper
local function loadAdminTools(self)
    Logger.Log(__FUNC__(), 'MisCordHelper - Loading AdminTools......')
    Script.ReloadScript('MisCordHelper/LogKeeper.lua')
    Script.ReloadScript('MisCordHelper/AdminTools.lua')
    local AdminTools = require 'MisCordHelper.AdminTools'
    self.AdminTools = AdminTools(self.PersistantStorage)
end

function g_MisCordHelper:init()
    Logger.Log(__FUNC__(), 'MisCordHelper - Starting....')
    createDefaultFiles(self)
    loadConfig(self)
    initServerLifetimeCounter(self)
    loadAdminTools(self)
    initialiseHTTPServer(self)
end

function g_MisCordHelper:start() Logger.Log(__FUNC__(), 'MisCordHelper - Running......') end
