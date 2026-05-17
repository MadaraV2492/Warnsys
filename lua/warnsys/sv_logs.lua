-- WarnSys :: Logs (Datei + Discord-Webhook)

WarnSys.Logs = {}
local LOG_DIR = "warnsys_logs"

if not file.IsDir(LOG_DIR, "DATA") then
    file.CreateDir(LOG_DIR)
end

local function logFileName()
    return LOG_DIR .. "/" .. os.date("%Y-%m-%d") .. ".txt"
end

function WarnSys.Logs.Write(line)
    local stamp = os.date("[%H:%M:%S] ")
    file.Append(logFileName(), stamp .. line .. "\n")
    if WarnSys.Config.Debug then
        print("[WarnSys/Log] " .. line)
    end
end

-- ============================================================
--  Discord-Webhook
-- ============================================================
local function discordPost(payload)
    local cfg = WarnSys.Config.Discord
    if not cfg.enabled or cfg.webhook == "" then return end

    local body = util.TableToJSON(payload)
    HTTP({
        url     = cfg.webhook,
        method  = "POST",
        headers = { ["Content-Type"] = "application/json" },
        body    = body,
        type    = "application/json",
        success = function(code)
            if code >= 400 then
                ErrorNoHalt("[WarnSys] Discord-Webhook HTTP " .. code .. "\n")
            end
        end,
        failed  = function(err)
            ErrorNoHalt("[WarnSys] Discord-Webhook fehlgeschlagen: " .. err .. "\n")
        end,
    })
end

function WarnSys.Logs.DiscordWarn(data)
    local cfg = WarnSys.Config.Discord
    discordPost({
        username   = cfg.username,
        avatar_url = cfg.avatar ~= "" and cfg.avatar or nil,
        embeds = {{
            title = "Neue Verwarnung",
            color = cfg.color,
            fields = {
                { name = "Spieler",  value = string.format("%s\n`%s`", data.nick, data.steamid), inline = true },
                { name = "Admin",    value = string.format("%s\n`%s`", data.admin_nick, data.admin_steamid), inline = true },
                { name = "Aktive Warns", value = tostring(data.activeCount or "?"), inline = true },
                { name = "Grund",    value = data.reason or "-", inline = false },
            },
            footer = { text = "WarnSys v" .. WarnSys.Version },
            timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ"),
        }},
    })
end

function WarnSys.Logs.DiscordUnwarn(data)
    local cfg = WarnSys.Config.Discord
    discordPost({
        username   = cfg.username,
        avatar_url = cfg.avatar ~= "" and cfg.avatar or nil,
        embeds = {{
            title = "Verwarnung entfernt",
            color = 3066993, -- grün
            fields = {
                { name = "Warn-ID", value = "#" .. tostring(data.id), inline = true },
                { name = "Spieler", value = string.format("%s\n`%s`", data.nick, data.steamid), inline = true },
                { name = "Entfernt von", value = data.admin_nick or "Konsole", inline = true },
            },
            timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ"),
        }},
    })
end

function WarnSys.Logs.DiscordAutoPunish(data)
    local cfg = WarnSys.Config.Discord
    discordPost({
        username   = cfg.username,
        avatar_url = cfg.avatar ~= "" and cfg.avatar or nil,
        embeds = {{
            title = "Auto-Bestrafung ausgelöst",
            color = 10038562, -- dunkelrot
            fields = {
                { name = "Spieler", value = string.format("%s\n`%s`", data.nick, data.steamid), inline = true },
                { name = "Aktion",  value = data.action, inline = true },
                { name = "Warns",   value = tostring(data.count), inline = true },
                { name = "Grund",   value = data.reason or "-", inline = false },
            },
            timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ"),
        }},
    })
end
