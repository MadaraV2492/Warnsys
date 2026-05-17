-- WarnSys :: Moderne Slide-In Notifications (Matte Black)
-- Überschreibt WarnSys.Util.Notify auf dem Client mit eigener UI.

surface.CreateFont("WS.Notify", { font = "Roboto", size = 16, weight = 600, antialias = true })
surface.CreateFont("WS.NotifyT",{ font = "Roboto", size = 13, weight = 400, antialias = true })

local TYPE_COLORS = {
    [0] = Color( 70, 200, 130), -- ok / generic
    [1] = Color(220,  50,  50), -- error
    [2] = Color(245, 180,  60), -- warn / hint
    [3] = Color( 80, 170, 255), -- info
}

local notifications = {}

local function push(msg, typ, dur)
    typ = typ or 0
    dur = dur or (WarnSys.Config and WarnSys.Config.NotifyDuration) or 6
    table.insert(notifications, 1, {
        msg     = msg,
        typ     = typ,
        color   = TYPE_COLORS[typ] or TYPE_COLORS[0],
        born    = SysTime(),
        dies    = SysTime() + dur,
        progress = 0,
        alpha   = 0,
        offset  = 60,
    })
    surface.PlaySound("buttons/lightswitch2.wav")
end

-- WarnSys.Util.Notify Client-Override
local function applyOverride()
    if not WarnSys.Util or WarnSys.Util._notifyOverridden then return end
    local original = WarnSys.Util.Notify
    WarnSys.Util._notifyOverridden = true
    function WarnSys.Util.Notify(ply, msg, typ)
        if ply == LocalPlayer() or not IsValid(ply) then
            push(msg, typ)
        elseif original then
            original(ply, msg, typ)
        end
    end
end
applyOverride()
hook.Add("InitPostEntity", "WarnSys.NotifyOverride", applyOverride)

-- Net-Receiver direkt nutzen (überschreibt den aus cl_net.lua, der notification.AddLegacy nutzt)
net.Receive("WarnSys.Notify", function()
    local msg = net.ReadString()
    local typ = net.ReadUInt(4)
    push(msg, typ)
end)

local PAD = 14
hook.Add("HUDPaint", "WarnSys.Notifications", function()
    local now = SysTime()
    local x = ScrW() - 24
    local y = ScrH() - 80

    for i = #notifications, 1, -1 do
        local n = notifications[i]
        local life = now - n.born
        local left = n.dies - now

        -- Sterben
        if left <= 0 then
            n.alpha = n.alpha - FrameTime() * 4
            n.offset = n.offset + FrameTime() * 200
            if n.alpha <= 0 then
                table.remove(notifications, i)
                goto continue
            end
        else
            n.alpha = math.min(1, n.alpha + FrameTime() * 6)
            n.offset = math.max(0, n.offset - FrameTime() * 400)
        end

        -- Größe berechnen
        surface.SetFont("WS.Notify")
        local tw, th = surface.GetTextSize(n.msg:gsub("\n.*", ""))
        local lines = {}
        for line in n.msg:gmatch("[^\n]+") do table.insert(lines, line) end
        local w = math.min(380, math.max(220, tw + PAD * 2 + 30))
        local h = 16 + #lines * 20

        local drawX = x - w + n.offset
        local drawY = y - h
        local a = math.Clamp(n.alpha * 255, 0, 255)

        -- Schatten
        for s = 1, 4 do
            local sa = a * (1 - s / 4) * 0.2
            draw.RoundedBox(6 + s, drawX - s, drawY - s, w + s * 2, h + s * 2,
                Color(0, 0, 0, sa))
        end

        -- Karte
        draw.RoundedBox(6, drawX, drawY, w, h, Color(18, 18, 22, a))
        -- Akzent links
        draw.RoundedBoxEx(6, drawX, drawY, 3, h,
            ColorAlpha(n.color, a), true, false, true, false)

        -- Icon
        local icon = n.typ == 1 and "✕" or n.typ == 2 and "⚠" or "i"
        draw.SimpleText(icon, "WS.Notify", drawX + 18, drawY + h / 2,
            ColorAlpha(n.color, a), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

        -- Text
        local ty = drawY + 10
        for _, line in ipairs(lines) do
            draw.SimpleText(line, "WS.Notify", drawX + 36, ty,
                Color(235, 235, 240, a), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
            ty = ty + 20
        end

        -- Progress-Leiste (Restzeit)
        if left > 0 then
            local total = n.dies - n.born
            local frac = left / total
            draw.RoundedBox(0, drawX, drawY + h - 2, w * frac, 2,
                ColorAlpha(n.color, a * 0.7))
        end

        y = y - h - 8
        ::continue::
    end
end)
