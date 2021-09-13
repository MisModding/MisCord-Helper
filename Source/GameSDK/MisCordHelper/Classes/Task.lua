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
---@class mTask
---@field   name          string      `Task Name`
---@field   status        string      `Task Status [sleeping|waiting|finished|dead]`
---@field   startTime     number      `Task start time (seconds since server/game start)`
---@field   finishTime    number      `Task finish time (seconds since server/game start)`
---@field   runCount      number      `Task run Count`
---@field   runLimit      number      `Task run Limit`
---@field   enabled       boolean     `is the Task Enabled`
local Task = Class('mTask', {})

--- Create a task.
---@param   name    string      `the task name`
---@param   fn      function    `the task method.`
--- Note: your task method must return `false, result` while its running
--- and `true, result` when compleated.
function Task:new(name, fn)
    --- This tasks Name
    self.name = name
    --- Current Task Status [sleeping,running,finished,dead]
    self.status = 'sleeping'
    --- is this Task enabled?
    self.enabled = false
    --- how many times this task ran since the last reset
    self.runCount = 0
    --- limit the number of times this task can run
    self.runLimit = nil
    --- when this task was started (in CPU time)
    self.startTime = nil
    --- when this task finished (in CPU time)
    self.finishTime = nil
    --- Task main method
    self.thread = coroutine.wrap(function(...)
        local args = (... or {nil})
        args = table.pack(args)
        local ranOk, compleated, result
        self.startTime = os.clock()
        while (not compleated) and (not self.enabled == false) do
            self.status = 'running'
            ranOk, compleated, result = pcall(fn, self, unpack(args))
            self.runCount = (self.runCount or 0) + 1
            if ranOk then
                if (not compleated) then
                    self.status = 'waiting'
                    if result then self.result = result end
                    local arg = table.pack(coroutine.yield(result))
                    if arg then args = arg end
                else
                    self.status = 'finished'
                    if result then self.result = result end
                    self.finishTime = os.clock()
                    return result
                end
            else
                self.status = 'dead'
                if result then self.result = result end
                return result
            end
            if (self.runLimit ~= nil) then if (self.runCount >= self.runLimit) then compleated = true end end
        end
        return result
    end)
end

--- Enable this Task
function Task:enable()
    if self.enabled then
        return false, 'already enabled'
    elseif self.status == 'dead' then
        return false, 'task error'
    elseif self.status == 'finished' then
        return false, 'task finished'
    end
    self.enabled = true
    return true, 'task enabled'
end

--- Disable this Task
function Task:disable()
    if (not self.enabled) then return false, 'already disabled' end
    self.enabled = false
    return true, 'task disabled'
end

--- Reset this task (allows you to run a finished or dead task)
function Task:reset()
    self.enabled = false
    self.status = 'sleeping'
    self.runCount = 0
    self.startTime = nil
    self.finishTime = nil
end

--- Run this Task
--- Any provided arguments will be passed to the tasks main method.
--- Note: you can only set these args once, subsequent calls to Task:run()
--- will use the same values as the first.
function Task:run(...)
    if (not self.enabled == true) then
        return false, 'Task not enabled'
    elseif (self.status == 'finished') then
        return false, 'Task compleated'
    elseif (self.status == 'dead') then
        return false, 'Task Error'
    end
    self.thread(...)
end

function Task:runAsync(delay, callback, ...)
    local args = table.pack(..., {nil})
    local new_thread = function()
        self:run(unpack(args))
        if (type(callback) == 'function') then callback(self) end
    end
    self.asyncTaskId = Script.SetTimerForFunction(delay, new_thread)
    return self.asyncTaskId
end

return Task ---@type mTask
