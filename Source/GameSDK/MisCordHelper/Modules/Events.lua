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

--[[

Usage:
  -- Create an event.
  Event:createEvent("join")

  -- Observe the event with a callback.
  -- The callback function will receive an event object
  -- which will have two parameters:
  --   .type -- a string, which is the type of this event.
  --   .args -- a table with data relative to this event.
  -- There is an optional 3rd argument to observe(), which
  -- if true, will create the event if it does not already
  -- exist.
  function a_callback(event,data,channelId)
    Log(string.format("I got an event: %s\n", event.type))
    Log(string.firmat("With data: %d \n",table.concat(data,","))
    Log(string.format("With %d arguments.\n", table.getn(event.args)))
  end

  Event:observe("join", a_callback)

  -- Emit the event!
  -- The second argument to emit() should be a table
  -- of data related to the event. It can be nil, in
  -- which case the created event object's .args
  -- property will be set to {}.
  Event:emit("join", {nick = "foobar", host = "..."},channelId)

  -- To no longer observe and event, pass in the callback
  -- function once again. Callbacks are matched based on
  -- the function you passed in. Remember, it HAS to be the
  -- same function; passing in anonymous functions won't work,
  -- unless you save the return value from Event.observe(),
  -- since it returns the callback function provided.
  Event.unobserve("join", a_callback)

  -- Silence an event if you wanted to prevent callbacks from
  -- being called.
  Event:silence("join")

  -- any callbacks won't be called now.
  Event:emit("join", {nick = "foobar", host = "..."},channelId)

  -- Allow callbacks to happen once more.
  Event:unsilence("join")

  -- You can remove events as well. This will remove
  -- the event and all of it's callbacks by setting the event
  -- to nil, allowing it to be garbage collected.
  Event:removeEvent("join")

]] --
---@class events
---[Event Manager Object]
---@field events table<string,function>
---@field callbacks table<string,function>
---@field silenced table<string,function>
local events = {
    events = {},
    callbacks = {},
    silenced = {}
}

--- Create an event.
function events:createEvent(event)
    if not self.events[event] then
        self.events[event] = {}
        self.callbacks[event] = {}
    end
end

--- Remove an event.
function events:removeEvent(event)
    self.events[event] = nil
    self.callbacks[event] = nil
end

--- Check to see if an event is known.
--- will be nil if it doesn't exist.
function events:hasEvent(event) return self.events[event] end

--- Observe an event. A callback function is required.
--- If do_create is true, and the event does not exist,
--- it will be created before storing the callback.
--- The callback function will be returned if it was
--- added, else nil is returned.
function events:observe(event, callback, do_create)
    if (not self:hasEvent(event)) and do_create then self:createEvent(event) end

    table.insert(self.callbacks[event], callback)

    return callback
end

--- No longer observe an event. The callback given to the
--- original observe() call must be given. It HAS to be
--- the same function, matching the function's ID, or else
--- the callback won't be removed. Thus, be careful passing
--- in anonymous functions as callbacks, unless you save the
--- return value from observe() to later use to unobserve.
function events:unobserve(event, callback)
    if self:hasEvent(event) then
        local tmp = {}

        for _, cb in self.callbacks[event] do if not callback == cb then table.insert(tmp, cb) end end

        self.callbacks[event] = tmp
        return true
    end

    return false
end

--- Emit an event. Callback functions are passed an
--- event object with .type and .data properties, with
--- .type being set to the type of event, and .data being
--- a provided table of values to be available to all observers.
--- any other args are appended to the calback function call
function events:emit(event, data, ...)
    local arg = {n = select('#', ...), ...}
    if self:hasEvent(event) and (not self:isSilenced(event)) then
        local ev = {type = event, args = (arg or {})}

        local result
        for idx, callback in ipairs(self.callbacks[event]) do
            if type(callback) == 'function' then result = callback(ev, data) end
        end
        return result or true
    end
end

--- Silence an event, causing any of it's callback
--- functions to not be called if the event is emitted.
function events:silence(event)
    if not self.silenced[event] then self.silenced[event] = true end

    return self.silenced[event]
end

--- Remove the silencing of an event.
function events:unsilence(event) self.silenced[event] = nil end

--- Checks to see if an event is silenced.
function events:isSilenced(event) return self.silenced[event] end

function events.new()
    local obj = {events = {}, callbacks = {}, silenced = {}}
    return setmetatable(obj, {__index = events})
end

setmetatable(events, {__call = function(self, ...) return self.new(...) end})

RegisterModule('MisCordHelper.Modules.Events', events)
return events
