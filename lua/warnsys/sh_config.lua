-- WarnSys :: Configuration
-- Alles, was du anpassen kannst, lebt hier.

WarnSys.Config = {}
local C = WarnSys.Config

-- ============================================================
--  Allgemein
-- ============================================================
C.Language       = "de"         -- "de" oder "en"
C.Prefix         = "[WarnSys]"   -- Chat-Prefix
C.ChatColor      = Color(231, 76, 60)
C.UseDarkRP      = true          -- Falls DarkRP installiert, nutze Notify-API
C.AdminGroupFallback = "superadmin" -- wenn ULX-Gruppe nicht existiert

-- ============================================================
--  Speicher
-- ============================================================
-- "sqlite"  -> integrierte sv.db (empfohlen, keine Konfiguration nötig)
-- "mysql"   -> MySQLOO (siehe sv_database.lua für Setup)
C.Storage = "sqlite"
C.MySQL = {
    host     = "127.0.0.1",
    port     = 3306,
    user     = "warnsys",
    pass     = "changeme",
    database = "gmod_warnsys",
}

-- ============================================================
--  Berechtigungen (ULX-Gruppen, die warnen / unwarnen dürfen)
--  "*" als Wildcard erlaubt JEDEM Spieler diese Aktion.
-- ============================================================
C.Permissions = {
    warn        = { "operator", "admin", "superadmin" },
    unwarn      = { "admin", "superadmin" },
    clearwarns  = { "superadmin" },
    viewWarns   = { "operator", "admin", "superadmin" }, -- fremde Warns lesen
    openMenu    = { "*" },                                 -- jeder darf das Menü öffnen
    editConfig  = { "superadmin" },
}

-- ============================================================
--  Panel-Tabs (was sieht wer im Menü?)
--  "*" = jeder. Sonst Liste der ULX-Gruppen, die den Tab sehen.
--  SuperAdmin sieht IMMER alles.
-- ============================================================
C.PanelTabs = {
    dashboard = { "*" },                                   -- Übersicht eigener Warns
    mywarns   = { "*" },                                   -- Eigene Verwarnungs-Historie
    admin     = { "operator", "admin", "superadmin" },     -- Andere Spieler verwarnen
    settings  = { "superadmin" },                          -- Server-Einstellungen
    help      = { "*" },                                   -- Befehle & Regeln
}

-- ============================================================
--  Anti-Abuse
-- ============================================================
C.MinReasonLength  = 3
C.MaxReasonLength  = 200
C.WarnCooldown     = 2          -- Sekunden zwischen zwei Warns desselben Admins
C.AllowSelfWarn    = false
C.AllowWarnHigherRank = false   -- Admin kann keinen SuperAdmin warnen

-- ============================================================
--  Auto-Bestrafung
-- ============================================================
-- Wird ausgelöst, wenn ein Spieler die angegebene Anzahl ACTIVER Warns erreicht.
-- type:   "kick", "tempban" (Minuten), "ban" (perma), "none"
-- Reihenfolge ist egal, der höchste passende Wert wird verwendet.
C.AutoPunish = {
    [3] = { type = "kick",    reason = "3 Verwarnungen erreicht." },
    [5] = { type = "tempban", time = 60,      reason = "5 Verwarnungen erreicht (1h Ban)." },
    [7] = { type = "tempban", time = 60 * 24, reason = "7 Verwarnungen erreicht (24h Ban)." },
    [10]= { type = "ban",     reason = "10 Verwarnungen erreicht (Perma-Ban)." },
}

-- ============================================================
--  Verwarnungs-Ablauf
-- ============================================================
-- Warns laufen automatisch nach X Tagen ab. 0 = nie.
C.ExpireDays = 30
-- Wenn true, werden abgelaufene Warns aus der "aktiven" Statistik entfernt,
-- aber im History-Tab weiter angezeigt.
C.KeepHistory = true

-- ============================================================
--  Voreingestellte Gründe (im Menü als Dropdown)
-- ============================================================
C.PresetReasons = {
    "RDM (Random Deathmatch)",
    "RDA (Random Arrest)",
    "NLR (New Life Rule)",
    "Metagaming",
    "Powergaming",
    "FailRP",
    "Prop-Block / Prop-Surf",
    "Beleidigung",
    "Werbung im Chat",
    "Ignorieren von Admins",
    "Cheating / Exploiting",
}

-- ============================================================
--  Benachrichtigungen
-- ============================================================
C.NotifySound      = "buttons/button10.wav"    -- Sound beim Verwarnt-werden
C.NotifyDuration   = 8                          -- Sekunden
C.NotifyAllAdmins  = true                       -- Admins sehen, wer wen warnt
C.BroadcastWarn    = false                      -- Server-weiter Chat-Broadcast

-- ============================================================
--  Discord-Webhook (leer lassen, um zu deaktivieren)
-- ============================================================
C.Discord = {
    enabled  = false,
    webhook  = "",
    username = "WarnSys",
    avatar   = "",
    color    = 15158332, -- Rot (Decimal)
}

-- ============================================================
--  Debug
-- ============================================================
C.Debug = false