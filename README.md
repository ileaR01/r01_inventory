# 🎒 FiveM Inventory System

A modular, lightweight inventory system built for performance and flexibility in **FiveM**. Supports **MongoDB** & **MySQL**, localized languages, and customizable weapon & vehicle logic.

---

![Preview](https://cdn.discordapp.com/attachments/1233752618153545869/1307748689392963686/image.png?ex=687685e0&is=68753460&hm=4aff4c1b48417ed44801de60e9eec54023206e89ceb9db41465602e6d939c678&)
<!-- Replace the image above with a real screenshot or GIF of your inventory UI -->

## 📌 Features

- 🔑 Easy-to-bind inventory key (`I` by default)
- ⚡ Fast Slot preview system (`TAB`)
- 🗃️ Supports both **MongoDB** and **MySQL**
- 🌍 Multi-language support (English & Romanian by default)
- 🔫 Custom weapon metadata (ammo types, weights, descriptions)
- 🚘 Intelligent trunk logic (rear-engine vehicle detection)
- 📦 Config-based, easy to extend and customize

---

## 🔧 Configuration

### Keybinds

```lua
Config.openKeyBind = 'I'
Config.showFastSlotsKeyBind = 'TAB'
```

### Database

```lua
Config.dataBaseType = 'mongodb' -- or 'mysql'
Config.dataBaseName = 'mongodb' -- Only used for MongoDB
```

### Language

```lua
Config.selectedLanguage = 'en' -- Options: 'en', 'ro'
```

Language strings are stored in `Config.Lang`. Example:

```lua
Config.Lang = {
  ['en'] = {
    ["acces_inventory"] = "Access inventory",
    ...
  },
  ['ro'] = {
    ["acces_inventory"] = "Acceseaza inventarul",
    ...
  }
}
```

---

## 🔫 Weapon List

Defined in `Config.waponsList`, each weapon entry includes:

```lua
[weaponHash] = {Label, Weight, Description, AmmoType}
```

Example:

```lua
['WEAPON_PISTOL'] = {'Pistol', 1.5, 'Standard semi-automatic handgun.', 'AMMO_PISTOL'}
['WEAPON_KNIFE'] = {'Knife', 1.0, 'A sharp melee weapon.', false}
```

---

## 🚗 Rear-Engine Vehicle Support

Some vehicles (like supercars) have their engine in the back.

```lua
Config.backEngines = {
  [`t20`] = true,
  [`zentorno`] = true,
  ...
}
```

This helps with proper trunk access or engine inspection logic.

---

## 🌍 Localization Helper

Get translated text dynamically using:

```lua
local msg = getLang("reload_weapon")
```

Automatically falls back to English if the key is missing.

---

## 🧪 Requirements

* `oxmysql`, `mysql-async` or a `MongoDB` resource