---@diagnostic disable: undefined-field
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
local HTTPServer = g_MisCordHelper.HTTPServer

local DataStore = g_MisCordHelper.PersistantStorage
local Settings = DataStore.Settings:GetPage('MisCordHelper_Config')
local AUTH_KEY = Settings['AuthKey']

local function GetPlayerList()
    local PlayerList = {}
    local OnlinePlayers = CryAction.GetPlayerList()
    if type(OnlinePlayers) == 'table' then
        for i, player in ipairs(OnlinePlayers) do
            InsertIntoTable(PlayerList, {
                Name = player:GetName(),
                SteamId = player.player:GetSteam64Id(),
                Location = player:GetWorldPos(),
                Health = player.player:GetHealth(),
            })
        end
    end
    return PlayerList
end

local function GetPlayerInfo(steamId)
    local player = {}
    local Players = GetPlayerList()
    local found_player = FindInTable(Players, 'SteamId', steamId)
    if not found_player then
        player = {Online = false, SteamId = steamId}
    else
        player = found_player
        player.Online = true
    end
    return player
end

local function GetBaseInfo(plotsign)
    local base = {Location = plotsign:GetWorldPos(), PartCount = plotsign.plotsign:GetPartCount()}
    -- get the plotsign owner
    local OwnerSteamId = plotsign.plotsign:GetOwnerSteam64Id()
    base.Owner = GetPlayerInfo(OwnerSteamId)
    return base
end

local function GetPlayerBases()
    -- table to hold all bases
    local PlayerBases = {}
    -- fetch a list of all players
    local PlotSigns = BaseBuildingSystem.GetPlotSigns()
    for _, plotsign in pairs(PlotSigns) do
        local base = GetBaseInfo(plotsign)
        InsertIntoTable(PlayerBases, base)
    end
    return PlayerBases
end

--- Used to Fetch a List containing information about All Entities of a Specified Class on the Server
---@param ClassName string      Entity Class Name to Search by. eg: 'AirDropCrate'
---@return table            returns a Lists as a table of entries {[1] = { Name = "AirDropCrate1", Location = { x=3312.0, y=-2344.2, z=35 } } }
local function GetInfoAllEntitiesByClass(ClassName)

    -- fetch all Entities of the specified class on Server
    local AllEnts = System.GetEntitiesByClass(ClassName)
    if not AllEnts then return 'There Are no ' .. ClassName .. ' found on Server' end -- backout if we dont find any

    local EntInfo = {}
    -- iterate all tents and grab name/position
    for i, entity in pairs(AllEnts) do
        InsertIntoTable(EntInfo, {
            --- You Can add Extra Properties to Return here
            Name = entity:GetName(),
            Location = entity:GetWorldPos(),
        })
    end
    return EntInfo
end

HTTPServer:addRoute('GET', '/locationInterop/locations/:kind', function(request)
    if not request.params then return false, 'Invalid params' end
    local params = request.params
    if (not params.auth_key) or (not params['auth_key'] == AUTH_KEY) then
        --- unauthorised
        return 401, 'Not Authorised'
    end
    if request['kind'] then
        if request['kind'] == 'air-crash' then
            return 200, GetInfoAllEntitiesByClass('AirPlaneCrash')
        elseif request['kind'] == 'air-drops' then
            return 200, GetInfoAllEntitiesByClass('AirDropCrate')
        elseif request['kind'] == 'players' then
            return 200, GetPlayerList()
        elseif request['kind'] == 'bases' then
            return 200, GetPlayerBases()
        elseif request['kind'] == 'tents' then
            local TentClasses = {
                'CampingTentBlue', 'CampingTentBrown', 'CampingTentGreen', 'CampingTentOrange', 'CampingTentPurple',
                'CampingTentRed', 'CampingTentYellow',
            }

            local AllTents = {}
            for _, TentClass in pairs(TentClasses) do
                local foundTents = GetInfoAllEntitiesByClass(TentClass)
                if type(foundTents) == 'table' then
                    for _, tent in pairs(foundTents) do InsertIntoTable(AllTents, tent) end
                end
            end
            return 200, AllTents
        else
            return 400, 'unknown Location Kind'
        end
    else
        return 400, 'must define a location Kind'
    end
end)
