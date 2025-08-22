RegisterServerEvent('r01:inventory:open')
RegisterServerEvent('r01:inventory:throwItem')
RegisterServerEvent('r01:inventory:moveItem')

RegisterServerEvent('r01:inventory:takeItem')
RegisterServerEvent('r01:inventory:moveItemSecond')

RegisterServerEvent('r01:inventory:setFastSlot')
RegisterServerEvent('r01:inventory:destroyItem')

RegisterServerEvent('r01:inventory:useItem')
RegisterServerEvent('r01:inventory:giveItem')
RegisterServerEvent('r01:inventory:giveBackAmmo')

local fastSlots = setmetatable({}, {__index = function(self, key) self[key] = {} return {} end})
local Inventory = {itemsData = {}}; GlobalState['r01:inventoryItems'] = Inventory.itemsData
local _rName = GetCurrentResourceName(); GlobalState['r01:inventory:_rName'] = _rName
local Drops = {}
local ammoCache = {}
local finishSync = false
local isDBconnected = false
local serverData = setmetatable({}, {
    __index = function(self, key)
        self[key] = {}

        return {}
    end,

    __newindex = function(self, key, value)
        if not value then
            if Config.dataBaseType == 'mongodb' then
                exports[Config.dataBaseName]:removeOne{collection = "inventories", query = {inventoryId = key}}
            else
                MySQL.Sync.execute("DELETE FROM inventories WHERE inventoryId = @inventoryId", {['@inventoryId'] = key})
            end
        else
            if not finishSync then goto next end

            if Config.dataBaseType == 'mongodb' then 
                exports[Config.dataBaseName]:updateOne{collection = 'inventoryes', query = {inventoryId = key}, update = {
                    ["$set"] = {
                        inventoryData = value,
                    }
                }}
            else
                MySQL.Sync.execute("INSERT INTO inventories (inventoryId, inventoryData) VALUES (@inventoryId, @inventoryData) ON DUPLICATE KEY UPDATE inventoryData = @inventoryData", {
                    ['@inventoryId'] = key,
                    ['@inventoryData'] = json.encode(value)
                })
            end

        end

        ::next::

        rawset(self, key, value)
    end
})

local getSlotByItem <const> = function(items, item)
    local theSlot = ""

    for k, v in pairs(items) do
        if v.item:lower() == item:lower() then
            theSlot = k
            break
        end
    end

    return tostring(theSlot)
end

local getInventoryFirstSlot <const> = function(items)
    local toReturn = 0
    
    while items[tostring(toReturn)] do
        toReturn += 1
    end

    return tostring(toReturn)
end

local createDropId <const> = function()
    ::remakeDrop::

    math.randomseed(os.time() + math.random(1,99))

    local dropId = "drop-"..os.time()..math.random(1,99)

    if Drops[dropId] then
        goto remakeDrop
    end

    return dropId
end

local countTable <const> = function(tbl)
    local t = 0

    for _ in pairs(tbl) do
        t += 1
    end

    return t
end

local hasItemOnFastSlot <const> = function(inventoryId, item)
    if not fastSlots[inventoryId] then return false end

    for slotId, v in pairs(fastSlots[inventoryId]) do
        if v:lower() == item:lower() then
            return slotId
        end
    end

    return -1
end

--=================================================================================================--
--==================================== Inventory base function ====================================--
--==================================== Inventory base function ====================================--
--==================================== Inventory base function ====================================--
--==================================== Inventory base function ====================================--
--=================================================================================================--

---@param src number
---@param secondId string
Inventory.openInventory = function(src, secondId)
    local inventoryId = GetPlayerIdentifierByType(src, 'license2')
    local whereModify = secondId:find('drop-') and Drops or serverData

    local secondItems = whereModify[secondId] or {}
    local userItems = serverData[inventoryId] or {}

    local myWeight = Inventory.getWeight(src)
    local secondWeight = Inventory.getWeight(secondId)
    
    TriggerClientEvent('r01:inventory:sendNuiMessage', src, {
        event = 'openInventory',
        data = {
            fastSlots = fastSlots[inventoryId], 
            userItems = userItems,
            charName = GetPlayerName(src),
            
            myWeight = ("%s/%skg"):format(myWeight, 30),

            secondData = {
                id = secondId,
                slots = 70,
                weight = ("%s/%skg"):format(secondWeight, 30),
                items = whereModify[secondId] or {}
            },
        }
    })
end

---@param inventory number / string
---@return number
Inventory.getWeight = function(inventory)
    local inventoryId = inventory
    local weight = 0

    inventoryId = type(inventoryId) == "number" and GetPlayerIdentifierByType(inventoryId, 'license2') or inventoryId

    local whereToFind = inventoryId:find('drop-') and Drops or serverData

    for _, data in pairs(whereToFind[inventoryId] or {}) do
        local itemWeight = Inventory.itemsData?[data.item]?.weight or 0

        weight += data.amount * itemWeight
    end

    return weight
end

---@param src number
---@param item string
---@param amount number
---@return boolean
Inventory.AddItem = function(src, item, amount)
    
    if not src or not item or not amount then return false end

    if type(amount) ~= "number" or amount <= 0 then return false end

    local item = item:lower()

    if not Inventory.itemsData[item] then return end
    
    local inventoryId = GetPlayerIdentifierByType(src, 'license2')
    local theSlot = getSlotByItem(serverData[inventoryId], item)

    theSlot = (theSlot ~= "") and theSlot or getInventoryFirstSlot(serverData[inventoryId])

    if serverData[inventoryId][theSlot] then
        serverData[inventoryId][theSlot].amount += amount
    else
        serverData[inventoryId][theSlot] = {
            item = item,
            amount = amount,
        }
    end

    local newWeight = Inventory.getWeight(inventoryId)

    TriggerClientEvent('r01:client:updateWeight', src, 'self', newWeight)
    TriggerClientEvent('r01:inventory:sendNuiMessage', src, {
        event = 'addInventoryItem',
        data = {theSlot, serverData[inventoryId][theSlot]}
    })


    return true
end

---@param src number
---@param item string
---@param amount number
---@return boolean
Inventory.RemoveItem = function(src, item, amount)
    local inventoryId = GetPlayerIdentifierByType(src, 'license2')
    local theSlot = getSlotByItem(serverData[inventoryId], item)
    
    if theSlot ~= "" and serverData[inventoryId][theSlot].amount >= amount then
        
        if item:upper():find("WEAPON_") then
            if ammoCache[src] and ammoCache[src][item:upper()] and ammoCache[src][item:upper()] > 0 then
                if not Config.throwableWeapons[item:upper()] then
                    TriggerClientEvent("r01:client:useWeapon", src, item:upper(), 0)
                end
            end
        end

        if serverData[inventoryId][theSlot].amount == amount then
            local fSlot = hasItemOnFastSlot(inventoryId, item)
            if fSlot ~= -1 then
                TriggerClientEvent('r01:client:removeFastSlot', src, fSlot)
            end

            serverData[inventoryId][theSlot] = nil
        else
            serverData[inventoryId][theSlot].amount -= amount
        end
        
        TriggerClientEvent('r01:inventory:sendNuiMessage', src, {
            event = 'removeInventoryItem',
            data = {theSlot, amount}
        })

        local newWeight = Inventory.getWeight(inventoryId)
        TriggerClientEvent('r01:client:updateWeight', src, 'self', newWeight)

        return true
    end

    return false
end


---@param item string
---@param label string
---@param desc string
---@param weight number
---@param func function
---@return table
Inventory.DefItem = function(item, label, desc, weight, func)
    Inventory.itemsData[item:lower()] = {
        label = label,
        desc = desc,
        weight = weight,
        func = func
    }

    GlobalState['r01:inventoryItems'] = Inventory.itemsData

    return Inventory.itemsData[item:lower()]
end

---@param inventory number / string
---@param item string
---@return number
Inventory.getItemAmount = function(inventory, item)
    local inventoryId = inventory

    inventoryId = type(inventoryId) == "number" and GetPlayerIdentifierByType(inventoryId, 'license2') or inventoryId

    local whereToFind = inventoryId:find('drop-') and Drops or serverData

    local theSlot = getSlotByItem(whereToFind[inventoryId], item)

    if theSlot ~= "" and whereToFind[inventoryId][theSlot].amount then
        return whereToFind[inventoryId][theSlot].amount
    end

    return 0
end

---@param inventory number / string
Inventory.saveInventory = function(inventory)
    local inventoryId = inventory

    inventoryId = type(inventoryId) == "number" and GetPlayerIdentifierByType(inventoryId, 'license2') or inventoryId

    if Config.dataBaseType == 'mongodb' then
        if not isDBconnected then return end

        exports[Config.dataBaseName]:updateOne{collection = 'inventoryes', query = {inventoryId = inventoryId}, update = {
            ["$set"] = {
                inventoryData = serverData[inventoryId] or {},
            }
        }}
    else
        if not isDBconnected then return end

        MySQL.Sync.execute("INSERT INTO inventories (inventoryId, inventoryData) VALUES (@inventoryId, @inventoryData) ON DUPLICATE KEY UPDATE inventoryData = @inventoryData", {
            ['@inventoryId'] = inventoryId,
            ['@inventoryData'] = json.encode(serverData[inventoryId] or {})
        })
    end
end

--======================================================================================--
--==================================== NUI function ====================================--
--==================================== NUI function ====================================--
--==================================== NUI function ====================================--
--==================================== NUI function ====================================--
--======================================================================================--

local openInventory <const> = function(secondId)
    Inventory.openInventory(source, secondId)
end; AddEventHandler('r01:inventory:open', openInventory)

local moveItem <const> = function(oldSlot, newSlot)
    local src = source
    local inventoryId = GetPlayerIdentifierByType(src, 'license2')

    if serverData?[inventoryId]?[oldSlot] then
        if serverData[inventoryId][newSlot] then
            local old = serverData[inventoryId][newSlot]
            serverData[inventoryId][newSlot] = serverData[inventoryId][oldSlot]
            serverData[inventoryId][oldSlot] = old
        else
            serverData[inventoryId][newSlot] = serverData[inventoryId][oldSlot]
            serverData[inventoryId][oldSlot] = nil
        end
    end
end; AddEventHandler('r01:inventory:moveItem', moveItem)

local moveItemSecond <const> = function(oldSlot, secondId, newSlot)
    local whereModify = secondId:find('drop-') and Drops or serverData

    if whereModify?[secondId]?[oldSlot] then
        if whereModify[secondId][newSlot] then
            local old = whereModify[secondId][newSlot]
            whereModify[secondId][newSlot] = whereModify[secondId][oldSlot]
            whereModify[secondId][oldSlot] = old
        else
            whereModify[secondId][newSlot] = whereModify[secondId][oldSlot]
            whereModify[secondId][oldSlot] = nil
        end
    end

end; AddEventHandler('r01:inventory:moveItemSecond', moveItemSecond)

local throwItem <const> = function(jsSlotId, secondId, jsSecondSlot, amount)
    local src = source

    local inventoryId = GetPlayerIdentifierByType(src, 'license2')
    
    local whereModify = secondId:find('drop-') and Drops or serverData
    local isNewDrop = false
    
    if secondId == "drop-new" then 
        secondId = createDropId()
        whereModify[secondId] = {}
        TriggerClientEvent('r01:client:createDrop', -1, {coords = GetEntityCoords(GetPlayerPed(src)), id = secondId})
    end

    if not jsSlotId or not secondId or not jsSecondSlot or not amount then return end
        
    if not serverData[inventoryId][jsSlotId] then return end

    if amount <= 0 or amount > serverData[inventoryId][jsSlotId].amount then return end
    
    if not whereModify[secondId] then return end
    
    if whereModify[secondId][jsSecondSlot] and whereModify[secondId][jsSecondSlot].item ~= serverData[inventoryId][jsSlotId].item then  return end
    
    local item = serverData[inventoryId][jsSlotId].item
    if item:upper():find("WEAPON_") then
        if ammoCache[src] and ammoCache[src][item:upper()] and ammoCache[src][item:upper()] > 0 then
            TriggerClientEvent("r01:client:useWeapon", src, item:upper(), 0)
        end
    end

    local itemExists = getSlotByItem(whereModify[secondId], serverData[inventoryId][jsSlotId]?.item or "")
    
    if itemExists ~= "" then
        whereModify[secondId][itemExists].amount = whereModify[secondId][itemExists].amount + amount
    else
        whereModify[secondId][jsSecondSlot] = {
            amount = amount,
            item = serverData[inventoryId][jsSlotId].item
        }
    end
    
    if amount == serverData[inventoryId][jsSlotId].amount then
        local fSlot = hasItemOnFastSlot(inventoryId, item)
        if fSlot ~= -1 then
            TriggerClientEvent('r01:client:removeFastSlot', src, fSlot)
        end

        serverData[inventoryId][jsSlotId] = nil
    else
        serverData[inventoryId][jsSlotId].amount = serverData[inventoryId][jsSlotId].amount - amount
    end

    local myNewWeight = Inventory.getWeight(inventoryId)
    local secondNewWeight = Inventory.getWeight(secondId)

    TriggerClientEvent('r01:client:updateWeight', src, 'self', myNewWeight)
    TriggerClientEvent('r01:client:updateWeight', src, secondId, secondNewWeight)
end; AddEventHandler('r01:inventory:throwItem', throwItem)

local takeItem <const> = function(jsSecondSlot, secondId, jsUserSlot, amount)
    local src = source

    local inventoryId = GetPlayerIdentifierByType(src, 'license2')
    
    local whereModify = secondId:find('drop-') and Drops or serverData

    if not jsSecondSlot or not secondId or not jsUserSlot or not amount then return end
    
    if not whereModify[secondId] or not whereModify[secondId][jsSecondSlot] then return end
    
    if amount <= 0 or amount > whereModify[secondId][jsSecondSlot].amount then return end
    
    if serverData[inventoryId][jsUserSlot] and serverData[inventoryId][jsUserSlot].item ~= whereModify[secondId][jsSecondSlot].item then return end
    
    local itemExists = getSlotByItem(serverData[inventoryId], whereModify[secondId][jsSecondSlot].item or "")
    
    if itemExists ~= "" then
        serverData[inventoryId][itemExists].amount = serverData[inventoryId][itemExists].amount + amount
    else
        serverData[inventoryId][jsUserSlot] = {
            amount = amount,
            item = whereModify[secondId][jsSecondSlot].item
        }
    end
    
    if amount == whereModify[secondId][jsSecondSlot].amount then
        whereModify[secondId][jsSecondSlot] = nil

        if countTable(whereModify[secondId]) == 0 then
            whereModify[secondId] = nil

            if secondId:find("drop-") then
                TriggerClientEvent('r01:client:removeDrop', -1, secondId)
            end
        end
    else
        whereModify[secondId][jsSecondSlot].amount = whereModify[secondId][jsSecondSlot].amount - amount
    end

    local myNewWeight = Inventory.getWeight(inventoryId)
    local secondNewWeight = Inventory.getWeight(secondId)
    TriggerClientEvent('r01:client:updateWeight', src, 'self', myNewWeight)
    TriggerClientEvent('r01:client:updateWeight', src, secondId, secondNewWeight)
end; AddEventHandler('r01:inventory:takeItem', takeItem)

local destroyItem <const> = function(jsUserSlot, amount)
    local src = source

    local inventoryId = GetPlayerIdentifierByType(src, 'license2')

    if not jsUserSlot or not amount then return end

    if not serverData[inventoryId][jsUserSlot] then return end

    if amount <= 0 or amount > serverData[inventoryId][jsUserSlot].amount then return end
    
    if serverData[inventoryId][jsUserSlot].amount == amount then
        serverData[inventoryId][jsUserSlot] = nil
    else
        serverData[inventoryId][jsUserSlot].amount -= amount
    end

    local newWeight = Inventory.getWeight(inventoryId)
    TriggerClientEvent('r01:client:updateWeight', src, 'self', newWeight)
end; AddEventHandler('r01:inventory:destroyItem', destroyItem)

local useItem <const> = function(item)
    local src = source

    local inventoryId = GetPlayerIdentifierByType(src, 'license2')

    if not item then return end

    local item = item:lower()

    local userSlot = getSlotByItem(serverData[inventoryId], item)

    if not serverData[inventoryId][userSlot] then return end
    
    if item:upper():find("WEAPON_") then
        local ammoItem = Config.weaponsList[item:upper()][4]

        if ammoCache[src] and ammoCache[src][item:upper()] then goto doEvent end

        if ammoItem then
            local ammoCount = Inventory.getItemAmount(src, ammoItem)
            
    
            ammoCount = ammoCount <= 250 and ammoCount or 250
    
            ammoCache[src] = ammoCache[src] or {}
            ammoCache[src][item:upper()] = ammoCount
    
            Inventory.RemoveItem(src, ammoItem, ammoCount)
        else
            ammoCache[src] = ammoCache[src] or {}
            ammoCache[src][item:upper()] = 1

            if Config.throwableWeapons[item:upper()] then
                Inventory.RemoveItem(src, item, 1)
            end
        end

        ::doEvent::
        TriggerClientEvent("r01:client:useWeapon", source, item:upper(), ammoCache[src][item:upper()])
        return
    end

    if not Inventory.itemsData[item]?.func then return end

    Inventory.itemsData[item].func(src, userSlot, serverData[inventoryId][userSlot])
end; AddEventHandler('r01:inventory:useItem', useItem)

local giveItem <const> = function(item, amount, nearPlayer)
    local src = source

    if not item or not amount then return end

    if amount <= 0 then return end
    
    if not nearPlayer or not GetPlayerName(nearPlayer) then return end

    local item = item:lower()

    if Inventory.RemoveItem(src, item, amount) then
        Inventory.AddItem(nearPlayer, item, amount)
    end
end; AddEventHandler('r01:inventory:giveItem', giveItem)

local setFastSlot <const> = function(slotId, item)
    local src = source

    local inventoryId = GetPlayerIdentifierByType(src, 'license2')
    
    if not item then goto finish end

    if not serverData[inventoryId][getSlotByItem(serverData[inventoryId], item)] then return end

    ::finish::

    fastSlots[inventoryId][slotId] = item
end; AddEventHandler('r01:inventory:setFastSlot', setFastSlot)

local giveAmmoBack <const> = function(weapon, needToGive)
    local src = source

    if not weapon or not needToGive then return end
    weapon = weapon:upper()

    if not ammoCache[src] or not ammoCache[src][weapon] then return end

    if needToGive > ammoCache[src][weapon] then return end

    ammoCache[src][weapon] = nil

    local ammoItem = Config.weaponsList[weapon][4]

    if Config.throwableWeapons[weapon] then
        ammoItem = weapon 
    end

    if not ammoItem then return end
    
    Inventory.AddItem(src, ammoItem, needToGive)

end; AddEventHandler('r01:inventory:giveBackAmmo', giveAmmoBack)

--======================================================================================--
--======================================= OTHERS =======================================--
--======================================= OTHERS =======================================--
--======================================= OTHERS =======================================--
--======================================= OTHERS =======================================--
--======================================================================================--

for weapon, data in pairs(Config.weaponsList) do
    local label = data[1]
    local weight = data[2]
    local desc = data[3]
    local ammoItem = data[4]

    Inventory.DefItem(weapon, label, desc, weight)

    if ammoItem and type(ammoItem) == "string" then
        Inventory.DefItem(ammoItem, label .. " Ammo", "Ammo for " .. label, 0.1)
    end
end


if Config.dataBaseType == 'mongodb' then
    AddEventHandler('onDatabaseConnect', function()
        isDBconnected = true

        print(('^2[%s]^7: '..getLang('db_connected').."!"):format(_rName))
    end)

    AddEventHandler('onResourceStart', function(rName)
        if rName ~= _rName then return end

        if exports[Config.dataBaseName]:isConnected() then
            isDBconnected = true
        else
        print(('^2[%s]^7: '..getLang('db_not_connected').."!"):format(_rName))
        end
    end)
else
    MySQL.ready(function()
        isDBconnected = true

        print(('^2[%s]^7: '..getLang('db_connected').."!"):format(_rName))
        MySQL.query('CREATE TABLE IF NOT EXISTS inventories (inventoryId VARCHAR(255) PRIMARY KEY, inventoryData TEXT)')
    end)
end

local fetchInventory <const> = function()
    if not isDBconnected then return end

    if Config.dataBaseType == "mongodb" then
        local result <const> = exports[Config.dataBaseName]:find{collection = 'inventoryes'}
        for _, data in pairs(result) do
            serverData[data.inventoryId] = data.inventoryData
        end
    else
        local result <const> = MySQL.Sync.execute("SELECT * FROM inventories")
        for _, data in pairs(result) do
            serverData[data.inventoryId] = json.decode(data.inventoryData)
        end
    end

    finishSync = true
end; AddEventHandler('onResourceStart', fetchInventory)
AddEventHandler('onDatabaseConnect', fetchInventory)

local playerLeave <const> = function()
    local src = source
    local inventoryId = GetPlayerIdentifierByType(src, 'license2')

    if not inventoryId then return end

    Inventory.saveInventory(inventoryId)
end; AddEventHandler('playerDropped', playerLeave)

local resourceStop <const> = function(rName)
    if rName ~= _rName then return end
    if not isDBconnected then return end

    for id, data in pairs(serverData) do
        Inventory.saveInventory(id)
    end
end; AddEventHandler('onResourceStop', resourceStop)

for k, v in pairs(Inventory) do
    exports(k, v)
end

exports('getFunctions', function()
    return setmetatable({}, {
        __index = function(self, key)
            self[key] = function(...)
                return exports[GlobalState['r01:inventory:_rName']][key](nil, ...)
            end
            
            return self[key]
        end
    })
end)