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
local router = require 'MisCordHelper.Modules.Router'
local JSON = require 'MisCordHelper.Modules.JSON'


-- | template http status codes.
local HTTPCODE = {
    [100] = 'CONTINUE',
    [200] = 'OK',
    [201] = 'CREATED',
    [202] = 'ACCEPTED',
    [203] = 'UNKNOWN MESSAGE', -- ? Fallback
    [302] = 'FOUND',
    [400] = 'BAD REQUEST',
    [401] = 'UNAUTHORISED',
    [403] = 'FORBIDDEN',
    [404] = 'NOT FOUND',
    [405] = 'METHOD NOT ALLOWED', -- ? Fallback: you should pass a message with this defining allowed methods GET|POST|?
    [500] = 'INTERNAL SERVER ERROR', -- ! Internal DONT USE THIS
}

---* get http status
---@param code number
function getHTTPCode(code)
    -- return if valid code
    return HTTPCODE[code]
end

-- ─── URL HANDLING ───────────────────────────────────────────────────────────────
--- Given a url like: `/some/path/endpoint?params` (params as Hex encoded json)
---| Extract the Route/Endpoint and parse any Params
function urldata(url)
    -- extract the route
    local function extract_route(url) for url_part in url:gmatch('(.+)%/') do return url_part end end
    -- Decode params
    local function urlparams(payload)
        local decoded, data = pcall(string.fromHex, payload)
        if decoded and data then
            local validJSON, params = pcall(JSON.parse, data)
            if validJSON and params then return params end
        end
        return {}
    end

    local route = extract_route(url)
    local endpoint, params = string.match(url, '([^/?]-)?([^,]-)$')
    if (not endpoint) or (endpoint == '') then endpoint = '@main' end
    return {route = route or '/', endpoint = endpoint, params = urlparams(params)}
end

---@class MisCordHelper.HTTPServer
local HTTP = Class('MisCordHelper.HTTPServer', {
    Routes = {
        --- GET Handlers
        GET = {}, ---@type table<string,function>
    },
})

function HTTP:new(routes)
    if routes and (routes['GET'] or routes['POST']) then self['Routes'] = table.update(self.Routes, routes) end
end

function HTTP:use()
    local app = router.new()
    app:match(self['Routes'])
    self.Router = app
    local _Router = self
    if not _G['GetHTTPURLAction'] then
        _G['GetHTTPURLAction'] = function(url, client, connection)
            local response = {status = 404, result = getHTTPCode(404), message = 'Failed to Handle Request'}
            return string.expand('${response}', {response = JSON.stringify(response)})
        end
    else
        RegisterCallbackReturnAware(_G, 'GetHTTPURLAction', nil, function(_, ret, url, client, connection)
            local Router = _Router
            --- request handled by router?
            local handled ---@type boolean
            -- request handler status
            local status ---@type string|number
            --- data sent back to the client, must be a string
            local result ---@type string
            handled, status, result = Router:Handle(url, client, connection)
            if handled and status then
                local response = {status = (status or 100), result = result, message = getHTTPCode(status or 100)}
                return string.expand('${response}', {response = JSON.stringify(response)})

            else
                local response = {status = 500, result = getHTTPCode(500), message = 'Failed to Handle Request'}
                return string.expand('${response}', {response = JSON.stringify(response)})
            end
            return ret
        end)
    end
end

function HTTP:addRoute(method, route, cb)
    local routes = self.Routes[method]
    if not routes then return false, 'unsupported method' end
    if routes[route] then return false, 'route exists' end

    if not type(cb) == 'function' then return false, 'invalid or missing callback' end
    routes[route] = cb
    self.Routes[method] = table.update(self.Routes[method], routes)

    if (self.Routes[method][route] == cb) then return true, 'route added' end
    return false, 'Unknown Error'
end

--- HTTP_SERVER Err Handler
local ERR_HTTP_HANDLER = function(err)
    local MSG = [[
        [ERROR:HTTP_SERVER]> ${FILEPATH}
        >> ${ERRMSG}
    ]]
    local message = string.expand(MSG, {FILEPATH = __FILE__(2), ERRMSG = err})
    LogError(message)
    return message
end

--- Handle HTTP Requests
function HTTP:Handle(url, client, connection)
    local method = 'GET'
    local request = urldata(url)
    local route = (request.route .. '/' .. request.endpoint)
    local params = table.update({method = method, client = client, connection = connection}, request)
    local ok, handled, status, result = xpcall(function() return self.Router:execute(method, url, params) end, ERR_HTTP_HANDLER) --- handle errors within Router:execute()
    if ok then if handled then return handled, status, result end end

    return false, 'unknown error'
end

RegisterModule('MisCordHelper.HTTPServer', HTTP)
return HTTP
