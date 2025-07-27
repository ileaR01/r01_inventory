RegisterNetEvent("r01:inventory:sendNuiMessage")
RegisterNetEvent("r01:client:showNotification")

RegisterNetEvent('r01:client:createDrop')
RegisterNetEvent('r01:client:removeDrop')

RegisterNetEvent("r01:client:useWeapon")
RegisterNetEvent("r01:client:doReload")

RegisterNetEvent("r01:client:updateWeight")
RegisterNetEvent("r01:client:removeFastSlot")

AddEventHandler("r01:inventory:sendNuiMessage", function(...)
    SendNUIMessage(...)
end)

AddEventHandler("r01:client:showNotification", function(message, type)
    if type == 'error' then
        print(('^1[%s]^7: %s'):format(GetCurrentResourceName(), message))
    else
        print(('^2[%s]^7: %s'):format(GetCurrentResourceName(), message))
    end
end)

RegisterNuiCallback('setFocus', function(data, cb)
    SetNuiFocus(data[1], data[1])
    
    cb('ok')
end)

RegisterNuiCallback('inventory:tryGetLang', function(data, cb)
    cb(Config.Lang[Config.selectedLanguage] or Config.Lang['en'])
end)

local equippedWeapon
local fastSlots = {}
local Drops = {}
local needToCloseCar
local backEngines = Config.backEngines
local uiLink = {
    .throwItem,
    .moveItem,

    .takeItem,
    .moveItemSecond,

    .destroyItem,

    .useItem,
    .giveItem
}

local GetClosestVehicle = function(coords)
    local ped = PlayerPedId()
    local vehicles = GetGamePool('CVehicle')
    local closestDistance = -1
    local closestVehicle = -1

    if coords then
        coords = type(coords) == 'table' and vec3(coords.x, coords.y, coords.z) or coords
    else
        coords = GetEntityCoords(ped)
    end

    for i = 1, #vehicles, 1 do
        local vehicleCoords = GetEntityCoords(vehicles[i])
        local distance = #(vehicleCoords - coords)

        if closestDistance == -1 or closestDistance > distance then
            closestVehicle = vehicles[i]
            closestDistance = distance
        end
    end
    
    return closestVehicle, closestDistance
end

local loadAnimDict = function(dict)
    if HasAnimDictLoaded(dict) then return end

    RequestAnimDict(dict)
    while not HasAnimDictLoaded(dict) do
        Wait(10)
    end
end

local updateWeight = function(inventoryId, weight)
    SendNUIMessage({
        event = 'updateWeight',
        data = {
            inventoryId = inventoryId,
            weight = ("%s/%skg"):format(weight, 30),
        }
    })
end; AddEventHandler("r01:client:updateWeight", updateWeight)

RegisterCommand('r01ScriptsOpenInventory', function()
    local second = "drop-new"
    local pPed = PlayerPedId()
    local pCoords = GetEntityCoords(pPed)

    for _, v in pairs(Drops) do
        local dist = #(pCoords - v.coords)

        if dist <= 2 then
            second = v.id
        end
    end

    local userVehicle = GetVehiclePedIsUsing(pPed)
    if userVehicle ~= 0 then
        second = "G-"..string.gsub(GetVehicleNumberPlateText(userVehicle), '^%s*(.-)%s*$', '%1')
    else
        local vehicle, dist = GetClosestVehicle(pCoords)

        if vehicle ~= 0 and vehicle ~= nil then
            local dimensionMin, dimensionMax = GetModelDimensions(GetEntityModel(vehicle))
            local trunkpos = GetOffsetFromEntityInWorldCoords(vehicle, 0.0, (dimensionMin.y), 0.0)

            if (backEngines[GetEntityModel(vehicle)]) then
                trunkpos = GetOffsetFromEntityInWorldCoords(vehicle, 0.0, (dimensionMax.y), 0.0)
            end

            if #(pCoords - trunkpos) < 1.5 and not IsPedInAnyVehicle(pPed) then
                if GetVehicleDoorLockStatus(vehicle) < 2 then
                    second = "T-"..string.gsub(GetVehicleNumberPlateText(vehicle), '^%s*(.-)%s*$', '%1')

                    loadAnimDict("amb@prop_human_bum_bin@idle_b")
                    TaskPlayAnim(pPed, "amb@prop_human_bum_bin@idle_b", "idle_d", 4.0, 4.0, -1, 50, 0, false, false, false)

                    SetVehicleDoorOpen(vehicle, 5, false, false)
                    needToCloseCar = vehicle
                end
            end

        end
    end

    TriggerServerEvent('r01:inventory:open', second)
end)

RegisterKeyMapping('r01ScriptsOpenInventory', getLang('acces_inventory'), 'keyboard', Config.openKeyBind)

for i = 1, 5 do
    RegisterCommand('useR01fastItem_'..i, function()
        local selected = tostring(i - 1)
        if fastSlots[selected] then
            TriggerServerEvent('r01:inventory:useItem', fastSlots[selected])
        end
    end)

    RegisterKeyMapping('useR01fastItem_'..i, getLang('use_slot')..' '..i, 'keyboard', i)
end

for k in pairs(uiLink) do
    RegisterNuiCallback('inventory:'..k, function(data, cb)
        TriggerServerEvent('r01:inventory:'..k, table.unpack(data))

        cb('ok')
    end)
end

RegisterNuiCallback("inventory:setFastSlot", function(data, cb)
    fastSlots[data[1]] = data[2]
    TriggerServerEvent("r01:inventory:setFastSlot", data[1], data[2])
    cb('ok')
end)

local removeFastSlot = function(slot)
    fastSlots[slot] = false
    SendNUIMessage({
        event = 'removeFastSlot',
        data = slot
    })
end; AddEventHandler("r01:client:removeFastSlot", removeFastSlot)

RegisterNuiCallback("inventory:closeInventory", function(data, cb)
    local ped = PlayerPedId()
    SetNuiFocus(false, false)
    
    if needToCloseCar then
        local vehicle = needToCloseCar
        
        SetVehicleDoorShut(vehicle, 5, false)
        ClearPedTasks(ped)
        needToCloseCar = nil
    end

    cb('ok')
end)

RegisterNuiCallback("inventory:getItemData", function(data, cb)
    local itemData = GlobalState['r01:inventoryItems'][data[1].item:lower()]

    cb(
        {
            label = itemData.label,
            item = data[1].item,
            desc = itemData.desc,
            weight = itemData.weight * data[1].amount,
            amount = data[1].amount,
        }
    )
end)

AddEventHandler('r01:client:createDrop', function(data)
    table.insert(Drops, data)
end)

AddEventHandler('r01:client:removeDrop', function(theId)    
    for k, v in pairs(Drops) do
        if v.id == theId then
            table.remove(Drops, k)
        end
    end
end)

Citizen.CreateThread(function()
    while true do
        local tks = 1000
        local ped = PlayerPedId()
        local pCoords = GetEntityCoords(ped)

        for _, v in pairs(Drops) do
            local dist = #(pCoords - v.coords)
            if dist <= 20 then
                tks = 1
                DrawMarker(20, v.coords.x, v.coords.y, v.coords.z - 0.8, .0, .0, .0, 180.0, .0, .0, .35, .35, .35, 130, 226, 102, 150, 1, 0, 0, 1)
            end
        end

        Wait(tks)
    end
end)


Citizen.CreateThread(function()
    local ped = PlayerPedId()
    RemoveAllPedWeapons(ped, true)
	SetPedConfigFlag(ped, 48, 1)
	SetPedCanSwitchWeapon(ped, 0)
	SetWeaponsNoAutoreload(1)
	SetWeaponsNoAutoswap(1)

    while true do
        DisableControlAction(0, 37, true) -- TAB
        Citizen.Wait(25)
    end
end)

-- tab preview
RegisterCommand('r01ScriptsShowFastSlots', function()
    SendNUIMessage({event = 'showFastSlotsPreview', data = fastSlots})
end)

RegisterKeyMapping('r01ScriptsShowFastSlots', getLang('show_fast_slots'), 'keyboard', Config.showFastSlotsKeyBind)

-- weapon handling
AddEventHandler("r01:client:useWeapon", function(weaponName, ammoCount)
    local ped = PlayerPedId()

    if equippedWeapon then
        local weaponHash = GetHashKey(equippedWeapon)
        local playerAmmo = GetAmmoInPedWeapon(ped, weaponHash)

        RemoveWeaponFromPed(ped, weaponHash)
        ClearPedTasksImmediately(ped)

        TriggerServerEvent("r01:inventory:giveBackAmmo", equippedWeapon, playerAmmo)

        equippedWeapon = nil
        return
    end

    local weaponHash = GetHashKey(weaponName)

    RemoveAllPedWeapons(ped)
    GiveWeaponToPed(ped, weaponHash, ammoCount or 0, false, true)
    SetPedAmmo(ped, weaponHash, ammoCount or 0)
    ClearPedTasksImmediately(ped)

    equippedWeapon = weaponName
end)

Citizen.CreateThread(function()
    while true do
        while equippedWeapon do
            local ped = PlayerPedId()
            local weaponHash = GetHashKey(equippedWeapon)
            local currentAmmo = GetAmmoInPedWeapon(ped, weaponHash)

            if currentAmmo < 1 then
                SetCurrentPedWeapon(ped, weaponHash, true)

                if Config.throwableWeapons[equippedWeapon] then
                    RemoveAllPedWeapons(ped)
                    TriggerServerEvent("r01:inventory:giveBackAmmo", equippedWeapon, 0)
                    equippedWeapon = nil
                end
            end

            Wait(100)
        end

        Wait(1500)
    end
end)

-- cloth handling
local savedClothing = {}
local cooldown = 0

local function playAnim(ped, animData)
    if not animData or not animData.Dict or not animData.Anim then return end
    RequestAnimDict(animData.Dict)
    while not HasAnimDictLoaded(animData.Dict) do
        Citizen.Wait(10)
    end
    TaskPlayAnim(ped, animData.Dict, animData.Anim, 3.0, 3.0, animData.Dur or 1000, 
        IsPedInAnyVehicle(ped) and 51 or (animData.Move or 0), 0, false, false, false)
    Citizen.Wait(animData.Dur or 1000)
end

local function toggleClothing(clothType, skipAnim)
    if not clothType or not Config.clothesTypes[clothType] then return end

    if not skipAnim and (cooldown > GetGameTimer()) then return end
    cooldown = GetGameTimer() + 100

    local ped = PlayerPedId()
    local isMale = (GetEntityModel(ped) ~= GetHashKey("mp_f_freemode_01"))
    local clothCfg = Config.clothesTypes[clothType]

    if savedClothing[clothType] then
        if not skipAnim then
            playAnim(ped, clothCfg.Emote.Off or clothCfg.Emote)
        end

        if clothCfg.type == "prop" then
            SetPedPropIndex(ped, clothCfg.id, savedClothing[clothType][1], savedClothing[clothType][2], true)
        elseif clothCfg.type == "drawable" then
            SetPedComponentVariation(ped, clothCfg.id, savedClothing[clothType][1], savedClothing[clothType][2])
        else
            for compId, compData in pairs(savedClothing[clothType]) do
                SetPedComponentVariation(ped, compId, compData[1], compData[2])
            end
        end

        savedClothing[clothType] = nil

    else
        if not skipAnim then
            playAnim(ped, clothCfg.Emote.On or clothCfg.Emote)
        end

        if clothCfg.type == "prop" then
            savedClothing[clothType] = {
                GetPedPropIndex(ped, clothCfg.id),
                GetPedPropTextureIndex(ped, clothCfg.id)
            }
            ClearPedProp(ped, clothCfg.id)

        elseif clothCfg.type == "drawable" then
            savedClothing[clothType] = {
                GetPedDrawableVariation(ped, clothCfg.id),
                GetPedTextureVariation(ped, clothCfg.id)
            }
            local data = isMale and clothCfg.male or clothCfg.female
            SetPedComponentVariation(ped, clothCfg.id, data[1], data[2])

        else
            savedClothing[clothType] = {}
            local genderCfg = isMale and clothCfg.male or clothCfg.female
            for compId, variation in pairs(genderCfg) do
                savedClothing[clothType][compId] = {
                    GetPedDrawableVariation(ped, compId),
                    GetPedTextureVariation(ped, compId)
                }
                SetPedComponentVariation(ped, compId, variation[1], variation[2])
            end
        end
    end
end

RegisterNuiCallback("inventory:useCloth", function(data, cb)
    toggleClothing(data[1])
    cb('ok')
end)

AddEventHandler("onResourceStop", function(resource)
    if resource ~= GetCurrentResourceName() then return end

    for clothType in pairs(Config.clothesTypes) do
        if savedClothing[clothType] then
            toggleClothing(clothType, true)
        end
    end
end)
