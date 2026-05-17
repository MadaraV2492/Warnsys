-- WarnSys :: Loader
-- Loads all shared/server/client files in the correct order.

WarnSys = WarnSys or {}
WarnSys.Version = "1.0.0"
WarnSys.Folder = "warnsys/"

local function loadFile(prefix, file)
    local path = WarnSys.Folder .. file
    if prefix == "sh" then
        if SERVER then AddCSLuaFile(path) end
        include(path)
    elseif prefix == "sv" then
        if SERVER then include(path) end
    elseif prefix == "cl" then
        if SERVER then
            AddCSLuaFile(path)
        else
            include(path)
        end
    end
end

local shared = {
    "sh_config.lua",
    "sh_lang.lua",
    "sh_util.lua",
}

local server = {
    "sv_database.lua",
    "sv_logs.lua",
    "sv_warns.lua",
    "sv_net.lua",
    "sv_ulx.lua",
    "sv_concmd.lua",
}

local client = {
    "cl_net.lua",
    "cl_hud.lua",
    "cl_menu.lua",
    "cl_warnlist.lua",
}

for _, f in ipairs(shared) do loadFile("sh", f) end
for _, f in ipairs(server) do loadFile("sv", f) end
for _, f in ipairs(client) do loadFile("cl", f) end

if SERVER then
    print("[WarnSys] v" .. WarnSys.Version .. " loaded (server).")
else
    print("[WarnSys] v" .. WarnSys.Version .. " loaded (client).")
end
