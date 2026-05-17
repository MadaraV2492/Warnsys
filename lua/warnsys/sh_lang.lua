-- WarnSys :: Übersetzungen

WarnSys.Lang = {}

WarnSys.Lang.de = {
    no_perm           = "Du hast keine Berechtigung dafür.",
    invalid_target    = "Ungültiger Spieler.",
    invalid_reason    = "Bitte gib einen gültigen Grund an (%d-%d Zeichen).",
    self_warn         = "Du kannst dich nicht selbst verwarnen.",
    higher_rank       = "Du kannst Spieler mit höherem Rang nicht verwarnen.",
    cooldown          = "Bitte warte %d Sekunden, bevor du erneut warnst.",
    warn_success      = "%s wurde verwarnt. Grund: %s",
    warn_received     = "Du wurdest verwarnt!\nGrund: %s\nVon: %s\nDu hast nun %d aktive Verwarnung(en).",
    unwarn_success    = "Verwarnung #%d entfernt.",
    unwarn_notfound   = "Diese Verwarnungs-ID existiert nicht.",
    clearwarns_ok     = "Alle Verwarnungen von %s gelöscht.",
    warnlist_empty    = "Keine aktiven Verwarnungen.",
    warnlist_header   = "Verwarnungen von %s (%d aktiv):",
    warnlist_line     = "  #%d  %s  von %s  am %s%s",
    expired_tag       = "  [ABGELAUFEN]",
    autopunish_kick   = "Spieler %s gekickt (Auto-Bestrafung).",
    autopunish_ban    = "Spieler %s gebannt (Auto-Bestrafung).",
    broadcast_warn    = "%s wurde von %s verwarnt. Grund: %s",
    menu_title        = "WarnSys :: Admin-Menü",
    menu_player       = "Spieler",
    menu_reason       = "Grund",
    menu_preset       = "Voreinstellung",
    menu_warn_btn     = "Verwarnen",
    menu_view_btn     = "Verwarnungen ansehen",
    menu_unwarn_btn   = "Entfernen",
    menu_clear_btn    = "Alle löschen",
    menu_refresh      = "Aktualisieren",
    menu_history      = "Verlauf",
    menu_active       = "Aktiv",
    menu_confirm_clear= "Wirklich ALLE Verwarnungen von %s löschen?",
    menu_confirm_unw  = "Verwarnung #%d wirklich entfernen?",
    cmd_warns_self    = "Deine Verwarnungen:",
    cmd_help          = "Befehle: !warn <spieler> <grund>, !warns, !warnmenu",
}

WarnSys.Lang.en = {
    no_perm           = "You don't have permission for that.",
    invalid_target    = "Invalid player.",
    invalid_reason    = "Please provide a valid reason (%d-%d characters).",
    self_warn         = "You can't warn yourself.",
    higher_rank       = "You can't warn players with a higher rank.",
    cooldown          = "Please wait %d seconds before warning again.",
    warn_success      = "%s has been warned. Reason: %s",
    warn_received     = "You have been warned!\nReason: %s\nBy: %s\nYou now have %d active warning(s).",
    unwarn_success    = "Warning #%d removed.",
    unwarn_notfound   = "Warning ID not found.",
    clearwarns_ok     = "All warnings of %s cleared.",
    warnlist_empty    = "No active warnings.",
    warnlist_header   = "Warnings of %s (%d active):",
    warnlist_line     = "  #%d  %s  by %s  on %s%s",
    expired_tag       = "  [EXPIRED]",
    autopunish_kick   = "Player %s kicked (auto-punish).",
    autopunish_ban    = "Player %s banned (auto-punish).",
    broadcast_warn    = "%s was warned by %s. Reason: %s",
    menu_title        = "WarnSys :: Admin Menu",
    menu_player       = "Player",
    menu_reason       = "Reason",
    menu_preset       = "Preset",
    menu_warn_btn     = "Warn",
    menu_view_btn     = "View Warnings",
    menu_unwarn_btn   = "Remove",
    menu_clear_btn    = "Clear All",
    menu_refresh      = "Refresh",
    menu_history      = "History",
    menu_active       = "Active",
    menu_confirm_clear= "Really delete ALL warnings of %s?",
    menu_confirm_unw  = "Really remove warning #%d?",
    cmd_warns_self    = "Your warnings:",
    cmd_help          = "Commands: !warn <player> <reason>, !warns, !warnmenu",
}

function WarnSys.L(key, ...)
    local lang = WarnSys.Lang[WarnSys.Config.Language] or WarnSys.Lang.en
    local str  = lang[key] or WarnSys.Lang.en[key] or key
    if select("#", ...) > 0 then
        return string.format(str, ...)
    end
    return str
end
