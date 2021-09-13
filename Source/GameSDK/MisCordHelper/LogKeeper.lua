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
---@class MisModding.LogKeeper
local LogKeeper = Class {}

---@param PersistantStorage PersistantStorage
function LogKeeper:new(PersistantStorage)
    local IsValidPersistantStorage, ReasonNotValid = isValidPersistantStorage(PersistantStorage)
    if (not IsValidPersistantStorage) then return false, ReasonNotValid end
    self.PersistantStorage = PersistantStorage
    return self
end

function LogKeeper:AddCatagory(catagory_name)
    -- fetch existing data
    local LogData = (self.PersistantStorage['Data']:GetPage('LogData') or {})
    -- Create empty Log catagory if it doesnt already exist.
    if (not LogData[catagory_name]) then
        LogData[catagory_name] = {}
        --- Save Data
        self.PersistantStorage['Data']:SetPage('LogData', LogData)
        return true, 'created'
    end
    return false, 'catagory exists'
end

---@class LogKeeper.logInfo
---@field action            string      "[required] Action to Log"
---@field reason            string      "[optional] Reason to Log"
---@field message           string      "[optional] Message to log"
---@field targetPlayer      string      "[optional] Target Player (steamId only) "
---@field actionedBy        string      "[optional] who commited this action"

--- logInfo validator
---@param logInfo LogKeeper.logInfo
local function valid_logInfo(logInfo)
    if assert_arg(1, logInfo, 'table') then return false, 'invalid logInfo (must be a table)' end
    -- Log Entries must Allways have an action and it must be of type String
    if (not type(logInfo['action']) == 'string') then return false, 'logInfo.action must be a String' end
    -- if logInfo.reason is specified it must be of type String
    if (logInfo['reason'] ~= nil) then
        if (not type(logInfo['reason']) == 'string') then return false, 'logInfo.reason must be a String' end
    end
    -- if logInfo.message is specified it must be of type String
    if (logInfo['message'] ~= nil) then
        if (not type(logInfo['message']) == 'string') then return false, 'logInfo.message must be a String' end
    end
    -- if logInfo.actionedBy is specified it must be of type String
    if (logInfo['targetPlayer'] ~= nil) then
        if (not type(logInfo['targetPlayer']) == 'string') then return false, 'logInfo.targetPlayer must be a String' end
        if (not isSteam64Id(logInfo['targetPlayer'])) then return false, 'logInfo.targetPlayer must be a steam64Id' end
    end
    -- if logInfo.actionedBy is specified it must be of type String
    if (logInfo['actionedBy'] ~= nil) then
        if (not type(logInfo['actionedBy']) == 'string') then return false, 'logInfo.actionedBy must be a String' end
    end
    return true, 'valid logInfo'
end

---* Logger:AddEntry(catagory, logInfo)
-- Records a new LogEntry for the specified catagory
---@param catagory string
---@param logInfo LogKeeper.logInfo
---@return boolean
---@return string
function LogKeeper:AddEntry(catagory, logInfo)
    -- fetch existing Data
    local LogData = (self.PersistantStorage['Data']:GetPage('LogData'))
    -- ensure we have a valid log catagory
    local target_log = LogData[catagory]
    if (not target_log) then return false, 'invalid log catagory' end
    -- check logInfo is valid
    local isValidLogInfo, logInfoValidatorResult = valid_logInfo(logInfo)
    if isValidLogInfo then
        -- create a temporary empty logEntry Object
        local logEntry = {
            time = os.date(),
            action = logInfo['action'],
            reason = (logInfo['reason'] or 'Undefined'),
            message = (logInfo['message'] or 'Undefined'),
            targetPlayer = (logInfo['targetPlayer'] or 'Undefined'),
            actionedBy = (logInfo['actionedBy'] or 'Undefined'),
        }
        --- Insert our new logEntry
        InsertIntoTable(target_log, logEntry)
        self.PersistantStorage['Data']:SetPage('LogData', LogData)
        return true, 'Log Entry added'
    else
        return false, logInfoValidatorResult
    end
end

---* Logger:GetLogs(catagory)
-- Fetch LogEntrys for the specified catagory
---@param catagory string
---@return table
function LogKeeper:GetLogs(catagory)
    -- fetch existing Data
    local LogData = (self.PersistantStorage['Data']:GetPage('LogData'))
    -- ensure we have a valid log catagory
    local target_log = LogData[catagory]
    if (not target_log) then
        return false, 'invalid log catagory'
    else
        return target_log
    end
end

RegisterModule('MisCordHelper.LogKeeper', LogKeeper)
return LogKeeper
