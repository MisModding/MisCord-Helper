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
local DEFAULT_FILES = {
    {
        file_name = 'Settings.cfg',
        file_path = './MisCord-Helper/Settings.cfg',
        file_content = [[

    # Dont Touch This
    VERSION_CFG = 0.1-alpha
    # Enable Debug Logging
    DEBUG = false
    # Interop API Key
    AuthKey = 0xSuperSecretKey

]],
    }, {
        file_name = 'README.md',
        file_path = './MisCord-Helper/README.md',
        file_content = [[

    # MisCord Helper

    for more information head to [MisCord-Helper](https://github.com/svaltek/MisCord/wiki)

    Created by: 
        - Theros <MisModding|SvalTek: github.com/SvalTek>
        - PitiViers <MisModding>

]],
    },
}

g_MisCordHelper['DEFAULT_FILES'] = DEFAULT_FILES
