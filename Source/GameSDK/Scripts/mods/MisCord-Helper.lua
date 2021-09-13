-- Copyright (C) 2021 Theros @[MisModding|SvalTek]
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
-- ────────────────────────────────────────────────────────────────────────────────
-- #region diag config
---@diagnostic disable: lowercase-global
-- #endregion


--- MisCord Helper Namespace
---@class MisCord-Helper
g_MisCordHelper = {
    --- Current Version
    VERSION = '0.1-alpha',
    --- Enable Debug mode
    DEBUG = false,
    --- MisCord Helper HTTP-Server
    HTTPServer = nil, ---@type MisCordHelper.HTTPServer
    --- MisCordHelper AdminTools
    AdminTools = nil, ---@type MisCordHelper.AdminTools
}
Script.ReloadScript('MisCordHelper/Common.lua')

g_MisCordHelper.Logger = CreateSimpleLogger("MisCordHelper", './MisCordHelper.log',3)
---NOTE Storing Main Methods in MisCord-Helper/main.lua to keep stuff clean
Script.ReloadScript('MisCordHelper/main.lua')

-- Handle Initialisation in OnInitPreloaded GameEvent
RegisterCallback(_G, 'OnInitPreloaded', nil, function()
    if (g_MisCordHelper['init']) then
        -- Initialise MisCord-Helper
        g_MisCordHelper:init()
    end
end)

-- Handle Startup in OnInitAllLoaded GameEvent
RegisterCallback(_G, 'OnInitAllLoaded', nil, function()
    if (g_MisCordHelper['start']) then
        -- Start MisCord-Helper
        g_MisCordHelper:start()
    end
end)
