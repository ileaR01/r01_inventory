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

Defined in `Config.weaponsList`, each weapon entry includes:

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

Example for vRP integration:

```lua

local cfgItems = module("cfg/items")

vRP.defInventoryItem = function(idname, name, description, weight, choices)
  local p = promise:new()

  Citizen.CreateThread(function()
    p:resolve(exports['r01_inventory']:DefItem(idname, name, description, weight, choices))
  end)

  return Citizen.Await(p)
end

vRP.giveInventoryItem = function(uId, item, amount)
  local src = vRP.getUserSource(uId)
  return exports['r01_inventory']:AddItem(src, item, amount)
end

vRP.tryGetInventoryItem = function(uId, item, amount)
  local src = vRP.getUserSource(uId)
  return exports['r01_inventory']:RemoveItem(src, item, amount)
end

vRP.getInventoryMaxWeight = function(myId)
  return 30
end

vRP.getInventoryItemAmount = function(myId, item)
  local src = vRP.getUserSource(myId)
  return exports['r01_inventory']:getItemAmount(src, item)
end

vRP.getItemWeight = function(item)
  local def = GlobalState['r01:inventoryItems'][item:lower()]
  return def?.weight or 0
end

vRP.getItemDefinition = function(item)
  return GlobalState['r01:inventoryItems'][item:lower()]
end

vRP.getItemDescription = function(item)
  local def = GlobalState['r01:inventoryItems'][item:lower()]
  return def?.desc or ""
end

vRP.getItemName = function(item)
  local def = GlobalState['r01:inventoryItems'][item:lower()]
  return def?.label or ""
end

vRP.openChest = function(src, name)
  return exports['r01_inventory']:openInventory(src, name)
end

for k,v in pairs(cfgItems) do
  vRP.defInventoryItem(k, v[1], v[2], v[3], v[4])
end

```

---

## 🧪 Requirements

* `oxmysql`, `mysql-async` or a `MongoDB` resource
