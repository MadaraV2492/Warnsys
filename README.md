# WarnSys – Garry's Mod Verwarnungs-System

Ein vollständiges Warn-System für Garry's Mod Roleplay-Server mit voller **ULX-Integration**, **SQLite/MySQL-Speicherung**, **GUI**, **Auto-Bestrafung**, **Discord-Webhook** und Mehrsprachigkeit (DE/EN).

> Branch: `claude/gmod-warn-system-cb2Hc`

---

## Features

- **Verwarnen** mit Grund (Chat, Konsole, ULX, GUI)
- **Unwarn** & **ClearWarns** (Admin / SuperAdmin)
- **Auto-Bestrafung** bei zu vielen Warns (Kick, Tempban, Permaban) – konfigurierbar
- **Warn-Ablauf** nach X Tagen (mit History-Tab)
- **GUI-Menü** mit Spielersuche, Voreinstellungen, Active/History Tabs
- **HUD-Anzeige** der eigenen aktiven Verwarnungen
- **SQLite** (default, keine Einrichtung) oder **MySQL** (MySQLOO)
- **Discord-Webhook** für Warn / Unwarn / AutoPunish
- **Rang-Schutz** (Admin kann keinen SuperAdmin warnen)
- **Cooldown** gegen Spam
- **DarkRP-Notify-Integration**, falls vorhanden
- **DE/EN** Sprachen, leicht erweiterbar
- **Hooks** für Drittanbieter (`WarnSys.PlayerWarned`, `WarnSys.PlayerUnwarned`, `WarnSys.PlayerCleared`)
- Funktioniert **mit und ohne ULX** (Fallback Chat-Befehle)

---

## Installation

1. Inhalt des `lua/`-Ordners in `garrysmod/addons/warnsys/lua/` legen, **oder** das ganze Repo direkt als Addon-Ordner ablegen:
   ```
   garrysmod/addons/warnsys/
   ├── lua/
   │   ├── autorun/sh_warnsys_init.lua
   │   └── warnsys/…
   └── README.md
   ```
2. Server starten – die Datei `sv.db` wird automatisch um die Tabelle `warnsys_warns` erweitert.
3. (Optional) `lua/warnsys/sh_config.lua` anpassen.
4. (Optional) ULX installieren, damit die `ulx warn` / `ulx unwarn` etc. Befehle sichtbar werden.

---

## Befehle

| Chat              | Konsole / ULX                       | Rang        | Funktion                          |
| ----------------- | ----------------------------------- | ----------- | --------------------------------- |
| `!warn <p> <g>`   | `ulx warn <p> <g>`                  | Admin       | Spieler verwarnen                 |
| `!unwarn <id>`    | `ulx unwarn <id>`                   | Admin       | Verwarnung entfernen              |
| `!clearwarns <p>` | `ulx clearwarns <p>`                | SuperAdmin  | Alle Warns eines Spielers löschen |
| `!warns [p]`      | `ulx warns [p]`                     | Alle/Admin  | Liste der Warns                   |
| `!mywarns`        | `warnsys_mywarns`                   | Alle        | Eigene Warns als GUI              |
| `!warnmenu`       | `ulx warnmenu` / `warnsys_menu`     | Admin       | Admin-GUI öffnen                  |
| –                 | `warnsys_warn <steamid> <g>`        | RCON/Konsole| Warnen via SteamID                |

---

## Ingame-Einstellungen (SuperAdmin)

Öffne das Menü mit `!warns` → Sidebar-Tab **Einstellungen**. Editierbar:

- **Allgemein**: Sprache (DE/EN), Grundlängen, Cooldown, Ablauf-Tage, Toggle-Flags
- **Auto-Bestrafung**: beliebig viele Regeln (Threshold + Kick/Tempban/Ban + Grund) hinzufügen/entfernen
- **MySQL**: Backend wechseln (SQLite ↔ MySQL), Host/Port/User/Pass/Datenbank, **Verbindung testen**
- **Discord**: Webhook aktivieren + URL + Anzeigename

Änderungen werden in `data/warnsys_runtime.json` gespeichert und beim Server-Start mit der Datei-Config gemerged. MySQL-Reconnect erfolgt automatisch.

---

## Konfiguration (`sh_config.lua`)

Die wichtigsten Optionen:

```lua
C.Language       = "de"           -- "de" oder "en"
C.Storage        = "sqlite"       -- oder "mysql"
C.ExpireDays     = 30             -- Auto-Ablauf nach X Tagen (0 = nie)

C.AutoPunish = {
    [3]  = { type = "kick",    reason = "..." },
    [5]  = { type = "tempban", time = 60,      reason = "..." },
    [7]  = { type = "tempban", time = 60 * 24, reason = "..." },
    [10] = { type = "ban",     reason = "..." },
}

C.Discord = {
    enabled = true,
    webhook = "https://discord.com/api/webhooks/...",
}
```

Berechtigungen werden über ULX-Gruppen geregelt:

```lua
C.Permissions = {
    warn       = { "operator", "admin", "superadmin" },
    unwarn     = { "admin", "superadmin" },
    clearwarns = { "superadmin" },
    viewWarns  = { "operator", "admin", "superadmin" },
    openMenu   = { "operator", "admin", "superadmin" },
}
```

---

## Hooks (für Entwickler)

```lua
hook.Add("WarnSys.PlayerWarned", "MyAddon", function(target, admin, data)
    -- data: { id, steamid, nick, admin_steamid, admin_nick, reason, created, expires, activeCount }
end)

hook.Add("WarnSys.PlayerUnwarned", "MyAddon", function(row, admin) end)
hook.Add("WarnSys.PlayerCleared",  "MyAddon", function(target, admin) end)
```

---

## Datenbank-Schema

```sql
CREATE TABLE warnsys_warns (
    id              INTEGER PRIMARY KEY AUTOINCREMENT,
    steamid         VARCHAR(32) NOT NULL,
    nick            VARCHAR(64),
    admin_steamid   VARCHAR(32),
    admin_nick      VARCHAR(64),
    reason          TEXT,
    created         INTEGER NOT NULL,
    expires         INTEGER DEFAULT 0,
    active          INTEGER DEFAULT 1
);
```

---

## MySQL-Setup (optional)

1. [MySQLOO](https://github.com/FredyH/MySQLOO) installieren.
2. In `sh_config.lua`:
   ```lua
   C.Storage = "mysql"
   C.MySQL = {
       host = "127.0.0.1", port = 3306,
       user = "warnsys", pass = "deinpass",
       database = "gmod_warnsys",
   }
   ```
3. Server neustarten.

---

## Logs

- Datei: `garrysmod/data/warnsys_logs/YYYY-MM-DD.txt`
- Discord: optional via Webhook (siehe Config)

---

## Lizenz

Frei nutzbar für deinen Server. Keine Garantie – Forks willkommen.
