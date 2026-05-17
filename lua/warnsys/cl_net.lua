-- WarnSys :: Client-Net-Receiver

WarnSys.Client = WarnSys.Client or {}
WarnSys.Client.ActiveWarns = 0
WarnSys.Client.LastList    = {}  -- [steamid] = { includeExpired, rows }

net.Receive("WarnSys.Notify", function()
    local msg = net.ReadString()
    local typ = net.ReadUInt(4)
    WarnSys.Util.Notify(LocalPlayer(), msg, typ)
end)

net.Receive("WarnSys.OpenMenu", function()
    if WarnSys.Client.OpenMenu then WarnSys.Client.OpenMenu() end
end)

net.Receive("WarnSys.UpdateCount", function()
    WarnSys.Client.ActiveWarns = net.ReadUInt(8)
end)

net.Receive("WarnSys.SendWarns", function()
    local sid = net.ReadString()
    local includeExpired = net.ReadBool()
    local count = net.ReadUInt(16)
    local rows = {}
    for i = 1, count do
        rows[i] = {
            id            = net.ReadUInt(32),
            nick          = net.ReadString(),
            admin_nick    = net.ReadString(),
            admin_steamid = net.ReadString(),
            reason        = net.ReadString(),
            created       = net.ReadUInt(32),
            expires       = net.ReadUInt(32),
            active        = net.ReadBool(),
        }
    end
    WarnSys.Client.LastList[sid] = { expired = includeExpired, rows = rows }
    hook.Run("WarnSys.WarnsReceived", sid, rows, includeExpired)
end)

function WarnSys.Client.RequestWarns(sid, includeExpired)
    net.Start("WarnSys.RequestWarns")
        net.WriteString(sid)
        net.WriteBool(includeExpired or false)
    net.SendToServer()
end
