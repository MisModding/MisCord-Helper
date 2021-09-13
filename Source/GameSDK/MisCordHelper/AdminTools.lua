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
local LogKeeper = require 'MisCordHelper.LogKeeper'

---@class MisCordHelper.AdminTools
local AdminTools = Class {}

function AdminTools:new(PersistantStorage)
    if assert_arg(1, PersistantStorage, 'table') then return false, 'must pass persistant storage object' end
    if (not PersistantStorage['Settings']) then
        return false, 'invalid PersistantStorage Object. must contain a [Settings] Source'
    end
    if (not PersistantStorage['Data']) then return false, 'invalid PersistantStorage Object. must contain a [Data] Source' end
    if (not PersistantStorage['Cache']) then return false, 'invalid PersistantStorage Object. must contain a [Cache] Source' end
    ----------------------------
    self.DataSource = PersistantStorage
    self.Logger = LogKeeper(PersistantStorage) ---@type MisModding.LogKeeper
    self.Logger:AddCatagory('MisCordHelper.AdminActions')
    return self
end

--
-- ──────────────────────────────────────────────────────── PLAYER MODERATION ─────
--

---* Kick a Player
---| takes `steam64Id`, "reason for kick", "name of admin actioning the kick of this player"
---@param steamId string
---@param reason string
---@param logInfo table
function AdminTools:KickPlayer(steamId, reason, logInfo)
    --- try to Detect if Player is Online
    local playerOnline
    for i, player in ipairs(CryAction.GetPlayerList()) do
        if player.player:GetSteam64Id() == steamId then
            playerOnline = true
            break
        end
    end
    --- Only allow Online Players to Be Kicked
    if playerOnline then
        self.Logger:AddEntry('MisCordHelper.AdminActions', {
            action = 'KickPlayer',
            targetPlayer = steamId,
            reason = reason,
            message = logInfo.message,
            actionedBy = logInfo.actionedBy,
        })
        System.ExecuteCommand('mis_kick ' .. steamId)
        return true, {status = 'sucess', result = string.format('Player with steamId %s has been kicked', steamId)}
    else
        return false, {status = 'fail', result = string.format('Player with steamId %s not online', steamId)}
    end
    return false, 'Unknown Error'
end

---* Ban a Player
---| takes `steam64Id`, "reason for Ban", "name of admin actioning the Ban of this player"
---@param steamId string
---@param reason string
---@param logInfo table
function AdminTools:BanPlayer(steamId, reason, logInfo)
    local ok, result
    local BanList = (self.DataSource.Data:GetPage('BanList') or {})
    if (not BanList[steamId]) then
        self.Logger:AddEntry('MisCordHelper.AdminActions', {
            action = 'BanPlayer',
            targetPlayer = steamId,
            reason = reason,
            message = logInfo.message,
            actionedBy = logInfo.actionedBy,
        })
        System.ExecuteCommand('mis_ban_steamid ' .. steamId)
        ok, result = true, 'Player added to BanList'
    else
        ok, result = false, 'Player already in BanList'
    end
    BanList[steamId] = true
    self.DataSource.Data:SetPage('BanList',BanList)
    return ok, result
end

---* UnBan a Player
---| takes `steam64Id`, "reason for unBan", "name of admin actioning the unBan of this player"
---@param steamId string
---@param reason string
---@param logInfo table
function AdminTools:UnbanPlayer(steamId, reason, logInfo)
    local ok, result
    local BanList = (self.DataSource.Data:GetPage('BanList') or {})
    if (BanList[steamId]) then
        self.Logger:AddEntry('MisCordHelper.AdminActions', {
            action = 'UnbanPlayer',
            targetPlayer = steamId,
            reason = reason,
            message = logInfo.message,
            actionedBy = logInfo.actionedBy,
        })
        System.ExecuteCommand('mis_ban_remove ' .. steamId)
        ok, result = true, 'Player removed from BanList'
    else
        ok, result = false, 'Player not in BanList'
    end
    BanList[steamId] = nil
    self.DataSource.Data:SetPage('BanList',BanList)
    return ok, result
end

RegisterModule('MisCordHelper.AdminTools',AdminTools)
return AdminTools