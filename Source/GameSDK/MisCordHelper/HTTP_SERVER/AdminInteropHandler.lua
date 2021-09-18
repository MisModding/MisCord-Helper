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
local ServerLifetime = g_MisCordHelper.ServerLifetime ---@type MisModding.simple_timer
local AUTH_KEY = Settings['AuthKey']


local VALID_LOG_TYPES = {['MisCordHelper.AdminActions'] = 'AdminActions'}
local function match_logType(kind) for key, value in pairs(VALID_LOG_TYPES) do if (value == kind) then return key end end end
_DEBUG = true

HTTPServer:addRoute(
    'GET', '/server', function(request)
        local onlinePlayers = CryAction.GetPlayerList()
        local player_count = table.size(onlinePlayers)
        local response_data = {
            serverName = System.GetCVar('sv_servername'),
            playerCount = tostring(player_count),
            server_lifetime = tostring(ServerLifetime:stats().lifetime),
            server_uptime = tostring(ServerLifetime:stats().runtime),
        }
        return 200, response_data
    end
)

HTTPServer:addRoute('GET', '/adminInterop/kick-player', function(request)
    if not request.params then return false, 'Invalid params' end
    local params = request.params
    if (not params.auth_key) or (not params['auth_key'] == AUTH_KEY) then
        --- unauthorised
        return 401, 'Not Authorised'
    end
    if (params['steamId'] and params['reason'] and params['actionedBy']) then
        local ok, result = g_MisCordHelper.AdminTools:KickPlayer(params.steamId, params.reason, {
            actionedBy = params.actionedBy,
            message = (params.message or 'Player Kicked'),
        })
        if ok and result then
            return 200, result
        else
            return 400, result
        end
    end
end)

HTTPServer:addRoute('GET', '/adminInterop/ban-player', function(request)
    if not request.params then return false, 'Invalid params' end
    local params = request.params
    if (not params.auth_key) or (not params['auth_key'] == AUTH_KEY) then
        --- unauthorised
        return 401, 'Not Authorised'
    end
    if (params['steamId'] and params['reason'] and params['actionedBy']) then
        local ok, result = g_MisCordHelper.AdminTools:BanPlayer(params.steamId, params.reason, {
            actionedBy = params.actionedBy,
            message = (params.message or 'Player Banned'),
        })
        if ok and result then
            return 200, result
        else
            return 400, result
        end
    end
end)

HTTPServer:addRoute('GET', '/adminInterop/unban-player', function(request)
    if not request.params then return false, 'Invalid params' end
    local params = request.params
    if (not params.auth_key) or (not params['auth_key'] == AUTH_KEY) then
        --- unauthorised
        return 401, 'Not Authorised'
    end
    if (params['steamId'] and params['reason'] and params['actionedBy']) then
        local ok, result = g_MisCordHelper.AdminTools:UnbanPlayer(params.steamId, params.reason, {
            actionedBy = params.actionedBy,
            message = (params.message or 'Player Unbanned'),
        })
        if ok and result then
            return 200, result
        else
            return 400, result
        end
    end
end)

HTTPServer:addRoute('GET', '/adminInterop/fetch-logs/:logKind', function(request)
    if not request.params then return false, 'Invalid params' end
    local params = request.params
    if (not params.auth_key) or (not params['auth_key'] == AUTH_KEY) then
        --- unauthorised
        return 401, 'Not Authorised'
    end
    local fetched_logs = {}
    if request['logKind'] then
        local log_type = match_logType(request['logKind'])
        fetched_logs = g_MisCordHelper.AdminTools.Logger:GetLogs(log_type)
    else
        fetched_logs = {}
        for log_type, _ in pairs(VALID_LOG_TYPES) do
            local data = g_MisCordHelper.AdminTools.Logger:GetLogs(log_type)
            if data then for _, log in pairs(data) do InsertIntoTable(fetched_logs, log) end end
        end
    end
    return 200, fetched_logs
end)
