Config = Config or {}

Config.openKeyBind = 'I' -- https://docs.fivem.net/docs/game-references/input-mapper-parameter-ids/
Config.showFastSlotsKeyBind = 'TAB' -- Key to show fast slots preview

Config.dataBaseType = 'mongodb' -- 'mysql' or 'mongodb'
Config.dataBaseName = 'mongodb' -- Name of the database resource (only in case of mongodb)

Config.selectedLanguage = 'en' -- 'en' or 'ro'
Config.Lang = { -- Language strings
    ['en'] = {
        -- backend
        ["acces_inventory"] = "Access inventory",
        ["use_slot"] = "Use slot",
        ["show_fast_slots"] = "Show fast slots",

        ["no_ammo_for"] = "You have no ammo for",
        ["reload_weapon"] = "Reload equipped weapon",

        ["db_connected"] = "Database connection established",
        ["db_not_connected"] = "Database connection failed",

        -- ui
        ['destroy_item_text'] = "Move your items here to destroy them, once destroyed they cannot be recovered",
        ['move_item'] = "Move item",
        ['move_item_desc'] = "Enter the amount you want to move in the box below, then press the confirm button.",

        ['destroy_item'] = "Destroy item",
        ['destroy_item_desc'] = "Move your items here to destroy them, once destroyed they cannot be recovered.",
    
        ['no_description'] = "This item doesn't have a description.",

        ['give_item'] = "Give item",
        ['give_item_desc'] = "Enter the amount you want to give in the box below, then press the confirm button.",
    },

    ['ro'] = {
        -- backend
        ["acces_inventory"] = "Acceseaza inventarul",
        ["use_slot"] = "Foloseste slotul",
        ["show_fast_slots"] = "Arata sloturile rapide",

        ["no_ammo_for"] = "Nu ai gloante pentru",
        ["reload_weapon"] = "Incarca arma echipata",

        ["db_connected"] = "Conexiunea la baza de date a fost stabilita",
        ["db_not_connected"] = "Conexiunea la baza de date a esuat",

        -- ui
        ['destroy_item_text'] = "Muta-ti itemele aici pentru a le distruge, odata distruse nu mai pot fi recuperate",
        ['move_item'] = "Muta itemul",
        ['move_item_desc'] = "Introdu in caseta de mai jos cantitatea pe care doresti sa o muti, apoi apasa pe butonul de confirmare.",

        ['destroy_item'] = "Distruge itemul",
        ['destroy_item_desc'] = "Muta-ti itemele aici pentru a le distruge, odata distruse nu mai pot fi recuperate.",
    
        ['no_description'] = "Acest item nu are descriere.",

        ['give_item'] = "Ofera itemul",
        ['give_item_desc'] = "Introdu in caseta de mai jos cantitatea pe care doresti sa o dai, apoi apasa pe butonul de confirmare.",
    }
}

Config.weaponsList = {
    -- [weaponHash] = {Label, Weight, Description, AmmoType}

    ['WEAPON_KNIFE'] = {'Knife', 1.0, 'A sharp melee weapon.', false},
    ['WEAPON_BAT'] = {'Baseball Bat', 2.0, 'A blunt melee weapon.', false},
    ['WEAPON_HAMMER'] = {'Hammer', 2.0, 'Tool or close-range weapon.', false},
    ['WEAPON_CROWBAR'] = {'Crowbar', 2.5, 'Heavy metal melee tool.', false},

    ['WEAPON_PISTOL'] = {'Pistol', 1.5, 'Standard semi-automatic handgun.', 'AMMO_PISTOL'},
    ['WEAPON_COMBATPISTOL'] = {'Combat Pistol', 1.6, 'Tactical law enforcement pistol.', 'AMMO_PISTOL'},
    ['WEAPON_APPISTOL'] = {'AP Pistol', 1.6, 'Fully automatic handgun.', 'AMMO_PISTOL'},
    ['WEAPON_PISTOL50'] = {'Pistol .50', 1.8, 'High caliber powerful handgun.', 'AMMO_PISTOL50'},

    ['WEAPON_MICROSMG'] = {'Micro SMG', 2.2, 'Compact submachine gun.', 'AMMO_SMG'},
    ['WEAPON_SMG'] = {'SMG', 2.4, 'Standard submachine gun.', 'AMMO_SMG'},
    ['WEAPON_ASSAULTSMG'] = {'Assault SMG', 2.5, 'High-capacity SMG.', 'AMMO_SMG'},

    ['WEAPON_ASSAULTRIFLE'] = {'Assault Rifle', 3.5, 'Fully automatic assault rifle.', 'AMMO_RIFLE'},
    ['WEAPON_CARBINERIFLE'] = {'Carbine Rifle', 3.6, 'Accurate, high-performance rifle.', 'AMMO_RIFLE'},
    ['WEAPON_ADVANCEDRIFLE'] = {'Advanced Rifle', 3.3, 'Compact modern rifle.', 'AMMO_RIFLE'},

    ['WEAPON_MG'] = {'Machine Gun', 4.5, 'High damage LMG.', 'AMMO_MG'},
    ['WEAPON_COMBATMG'] = {'Combat MG', 5.0, 'Tactical light machine gun.', 'AMMO_MG'},

    ['WEAPON_PUMPSHOTGUN'] = {'Pump Shotgun', 3.8, 'Classic pump-action shotgun.', 'AMMO_SHOTGUN'},
    ['WEAPON_SAWNOFFSHOTGUN'] = {'Sawed-Off Shotgun', 3.0, 'Short barrel shotgun.', 'AMMO_SHOTGUN'},
    ['WEAPON_BULLPUPSHOTGUN'] = {'Bullpup Shotgun', 3.6, 'Modern compact shotgun.', 'AMMO_SHOTGUN'},

    ['WEAPON_SNIPERRIFLE'] = {'Sniper Rifle', 6.0, 'Precision long-range rifle.', 'AMMO_SNIPER'},
    ['WEAPON_HEAVYSNIPER'] = {'Heavy Sniper', 7.0, 'High-caliber sniper rifle.', 'AMMO_SNIPER'},

    ['WEAPON_GRENADE'] = {'Grenade', 0.5, 'Throwable explosive.', false},
    ['WEAPON_MOLOTOV'] = {'Molotov Cocktail', 0.6, 'Incendiary weapon.', false},

    ['WEAPON_STUNGUN'] = {'Taser', 1.0, 'Non-lethal electroshock weapon.', false},
    ['WEAPON_FLASHLIGHT'] = {'Flashlight', 0.3, 'Used for lighting.', false},
}

Config.backEngines = { -- list of vehicles that has engine in the back (not all, you can add more)
    [`ninef`] = true,
    [`adder`] = true,
    [`vagner`] = true,
    [`t20`] = true,
    [`infernus`] = true,
    [`zentorno`] = true,
    [`reaper`] = true,
    [`comet2`] = true,
    [`comet3`] = true,
    [`jester`] = true,
    [`jester2`] = true,
    [`cheetah`] = true,
    [`cheetah2`] = true,
    [`prototipo`] = true,
    [`turismor`] = true,
    [`pfister811`] = true,
    [`ardent`] = true,
    [`nero`] = true,
    [`nero2`] = true,
    [`tempesta`] = true,
    [`vacca`] = true,
    [`bullet`] = true,
    [`osiris`] = true,
    [`entityxf`] = true,
    [`turismo2`] = true,
    [`fmj`] = true,
    [`re7b`] = true,
    [`tyrus`] = true,
    [`italigtb`] = true,
    [`penetrator`] = true,
    [`monroe`] = true,
    [`ninef2`] = true,
    [`stingergt`] = true,
    [`surfer`] = true,
    [`surfer2`] = true,
    [`gp1`] = true,
    [`autarch`] = true,
    [`tyrant`] = true,
    [`coquette4`] = true,
}

_G.getLang = function(key)
    local lang = Config.Lang[Config.selectedLanguage] or Config.Lang['en']

    if not lang[key] then
        print(('^1[%s]^7: Language key "%s" not found!'):format(GetCurrentResourceName(), key))
        return key
    end

    return lang[key]
end
