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
-- ────────────────────────────────────────────────────────────── SIMPLETIMER ─────
--
--- Stores Big Numbers as strings
-- ? Lua 5.1 lacks precision with big numbers, this results in string conversions using scientific notation
-- ? you can get around this using string.format, this wraps a Save/Read method for handling Large numbers as strings
local BigNum = {Save = function(num) return string.format('%.f', num) end, Read = function(numStr) return tonumber(numStr) end}

--- Used internally to update timer stats
local function timer_update(timer)
    if not timer.timer_active then return end
    local timeNow = os.time()
    local timer_created = BigNum.Read(timer.created)
    local timer_started = BigNum.Read(timer.started)
    local runtime = timeNow - timer_started
    local lifetime = timeNow - timer_created
    timer.runtime = BigNum.Save(runtime)
    timer.lifetime = BigNum.Save(lifetime)
end

---@class MisModding.simple_timer
---* Simple Timer Class
local timer = Class {}

---*Create a new Timer
---| optionaly: provide the epoch to continue an existing timer.
function timer:new(epoch)
    self.state = {}
    self.state['created'] = BigNum.Save(epoch or os.time())
    return self
end

---* Start this timer
---| returns true or false if timer is allready running
---| and the epoch start time
function timer:start()
    --- grab start time asap
    local started = BigNum.Save(os.time())
    if (self.state['timer_active'] ~= true) then
        self.state['timer_active'] = true
        self.state['started'] = started
        timer_update(self.state)
        return true, started
    end
    return false
end

---* Stop this timer
---| returns true or false if timer is allready stopped
function timer:stop()
    --- grab stop time asap
    local stopped = BigNum.Save(os.time())
    if (self.state['timer_active'] ~= false) then
        timer_update(self.state)
        self.state['timer_active'] = false
        self.state['stopped'] = stopped
        return true, stopped
    end
    return false
end

---* Resets this timers runtime, does NOT reset the lifetime or creation stats.
function timer:reset()
    timer_update(self.state)
    local reset = os.time()
    self.state['reset'] = reset
    self.state['runtime'] = 0
    self.state['lastreset'] = os.time()
    return true, reset
end

---* fetch this timers stats.
function timer:stats()
    timer_update(self.state)
    return {
        created = self.state['created'],
        started = self.state['started'],
        stopped = self.state['stopped'],
        runtime = self.state['runtime'],
        lifetime = self.state['lifetime'],
    }
end

RegisterModule('MisCordHelper.Classes.Timer', timer)
return timer
