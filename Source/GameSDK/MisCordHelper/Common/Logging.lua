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

---create a new simple logger
---@param name string
---@param path string
---@param level number
---@return simple_logger|boolean simple_logger instance or false
---@return nil|string error message
function CreateSimpleLogger(name,path,level)
    if assert_arg(1,name,'string') then return false, "invalid Log name - Must be a String" end
    if assert_arg(2,path,'string') then return false, "invalid Log file path - Must be a String" end
    if (level == nil) then
        level = 1
    else
        if assert_arg(3,level,'number') then return false, "invalid Log Level - Must be a Number" end
    end

    ---@class simple_logger
    local logger = {
        LOG_NAME = name,
        --- Path to File this Logger Writes to.
        LOG_FILE = path,
        --- this Loggers cuurrent Log Level
        LOG_LEVEL = level
    }

    local template = [[ ${name} [${level}:${prefix}] >> 
            ${content}"]]

    local logfile = {
        path = logger.LOG_FILE,
        update = function(self, line)
            local file = io.open(self.path, 'a+')
            if file then
                file:write(line .. '\n')
                file:close()
                return true, 'updated'
            end
            return false, 'failed to update file: ', (self.path or 'invalid path')
        end,
        purge = function(self) os.remove(self.path) end,
    }

    local function isDebug()
        local dbg = false
        if (System.GetCVar('log_verbosity') == 3) then
            dbg = true
        elseif (logger.LOG_LEVEL >= 3) then
            dbg = true
        end
        return dbg
    end

    local function writer(logtype, source, message)
        local logname = logger['LOG_NAME'] or "Logger"
        local line = string.expand(template, {name = logname, level = logtype, prefix = source, content = message})
        return logfile:update(os.date() .. '  >> ' .. line)
    end

    --- Writes a [Log] level entry to the mFramework log
    logger.Log = function(source, message)
        if not (logger.LOG_LEVEL >= 1) then return end
        return writer('LOG', source, message)
    end

    --- Writes a [Error] level entry to the mFramework log
    logger.Err = function(source, message)
        if not (logger.LOG_LEVEL >= 1) then return end
        return writer('ERROR', source, message)
    end

    --- Writes a [Warning] level entry to the mFramework log
    logger.Warn = function(source, message)
        if not (logger.LOG_LEVEL >= 2) then return end
        return writer('WARNING', source, message)
    end
    --- Writes a [Debug] level entry to the mFramework log
    logger.Debug = function(source, message)
        if not isDebug() then return end
        return writer('DEBUG', source, message)
    end

    logfile:purge()
    return logger
end

